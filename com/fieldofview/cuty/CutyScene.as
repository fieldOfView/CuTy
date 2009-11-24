package com.fieldofview.cuty {
	import flash.display.*;
	import flash.geom.*;
	import flash.events.*;
	import flash.ui.Keyboard;
	import flash.utils.ByteArray;

	import com.fieldofview.qtparser.MovParser;

	public class CutyScene extends Sprite {
		public var built:Boolean;
		public var allDone:Boolean;
		public var message:String;

		public var panSpeed:Number = 0;
		public var tiltSpeed:Number = 0;
		public var fovSpeed:Number = 0;

		public var pan:Number = 0;
		public var tilt:Number = 0;
		public var fov:Number = 90;

		public var panLimits:Object = {min:-180, max:180};
		public var tiltLimits:Object = {min:-90, max:90};
		public var fovLimits:Object = {min:20, max:160};

		private var camera:Sprite;
		private var tiles:Array;

		private var dragLoc:Point;
		private var mouseLoc:Point;
		private var dragging:Boolean;

		private var forcedZoom:Boolean = false;

		private static var PLACEHOLDER:uint = 0;
		private static var LOADING_PREVIEW:uint = 1;
		private static var PREVIEW:uint = 2;
		private static var LOADING_FULL:uint = 3;
		private static var FULL:uint = 4;

		public var eventDispatcher:EventDispatcher = new EventDispatcher();
		public static var ERROR:String = "error";
		public static var INFO:String = "info";

		public function CutyScene(__parent:Sprite):void {
			__parent.addChildAt(this, 0);

			camera = new Sprite();
			camera.rotationY = 0;
			this.addChild(camera);

			resize(new Event(""));

			// set up events
			this.addEventListener(Event.ENTER_FRAME, draw);
			stage.addEventListener(Event.RESIZE, resize);

			stage.addEventListener(MouseEvent.MOUSE_DOWN, dragStart);
			stage.addEventListener(MouseEvent.MOUSE_UP, dragEnd);
			stage.addEventListener(MouseEvent.MOUSE_MOVE, mouseMove);
			stage.addEventListener(KeyboardEvent.KEY_DOWN, keyDown);
			stage.addEventListener(KeyboardEvent.KEY_UP, keyUp);
		}

		public function build(__mov:MovParser):void {
			var cube:Sprite = new Sprite();
			cube.rotationY = 0;
			camera.addChild(cube);

			sendLog("Getting scene info...", INFO);
			if (__mov.metaData.title != "")
				sendLog("Title:" + __mov.metaData.title, INFO);
			if (__mov.metaData.author != "")
				sendLog("Author:" + __mov.metaData.author, INFO);
			if (__mov.metaData.copyright != "")
				sendLog("Copyright: " + __mov.metaData.copyright, INFO);

			panLimits = {min:__mov.cameraParameters[0], max:__mov.cameraParameters[1]};
			tiltLimits = {min:__mov.cameraParameters[2], max:__mov.cameraParameters[3]};
			fovLimits = {min:__mov.cameraParameters[4], max:__mov.cameraParameters[5]};

			pan = __mov.cameraParameters[6];
			tilt = __mov.cameraParameters[7];
			fov = __mov.cameraParameters[8];

			sendLog("Building placeholder tiles...", INFO);
			var size:Number = 256;
			var placeholder:Sprite = new Sprite();

			tiles = new Array();

			placeholder.graphics.lineStyle(24, 0xF0F0F0);
			placeholder.graphics.beginFill(0xFFFFFF);
			placeholder.graphics.drawRect( 0, 0, size, size);
			placeholder.graphics.moveTo(0,0);
			placeholder.graphics.lineTo(size,size);
			placeholder.graphics.moveTo(size,0);
			placeholder.graphics.lineTo(0,size);

			var placeholderBitmap:BitmapData = new BitmapData(size, size);
			placeholderBitmap.draw(placeholder);

			var tileSubdivisions:Number = Math.sqrt(__mov.tileInfo.length / 6);

			for each (var tile:Object in __mov.tileInfo) {
				var sprite:Sprite = new Sprite();
				var location:Object;

				if        (tile.orientation[0] != 0 && tile.orientation[1] == 0  && tile.orientation[2] == 0) {
					sprite.rotationY = 0;
					location = {x: tile.center[0] -1, y:-tile.center[1] -1, z: tileSubdivisions};
				} else if (tile.orientation[0] >  0 && tile.orientation[1] == 0  && tile.orientation[2] ==-tile.orientation[0]) {
					sprite.rotationY = 90;
					location = {x: tileSubdivisions, y:-tile.center[1] -1, z:-tile.center[0] +1};
				} else if (tile.orientation[0] == 0 && tile.orientation[1] == 0  && tile.orientation[2] != 0) {
					sprite.rotationY = 180;
					location = {x:-tile.center[0] +1, y:-tile.center[1] -1, z:-tileSubdivisions};
				} else if (tile.orientation[0] != 0 && tile.orientation[1] == 0  && tile.orientation[2] == tile.orientation[0]) {
					sprite.rotationY =-90;
					location = {x:-tileSubdivisions, y:-tile.center[1] -1, z: tile.center[0] -1};
				} else if (tile.orientation[0] != 0 && tile.orientation[1] ==-tile.orientation[0] && tile.orientation[2] == 0) {
					sprite.rotationX =-90;
					location = {x: tile.center[0] -1, y: tileSubdivisions, z: tile.center[1] +1};
				} else if (tile.orientation[0] != 0 && tile.orientation[1] == tile.orientation[0] && tile.orientation[2] == 0) {
					sprite.rotationX = 90;
					location = {x: tile.center[0] -1, y:-tileSubdivisions, z:-tile.center[1] -1};
				}

				populateSprite(sprite, location, size, placeholderBitmap);

				cube.addChildAt(sprite, 0);

				tiles.push ({location:location, sprite:sprite, size:size,
					start:tile.start, length:tile.length, 
					previewStart:tile.previewStart, previewLength:tile.previewLength, 
					state:PLACEHOLDER});
			}

			built = true;
			draw(new Event(""));
		}

		public function updateTiles(__movContent:ByteArray):void {
			for each (var tile:Object in tiles) {
				if(tile.state as uint < LOADING_FULL) {
					if (__movContent.length >= tile.start + tile.length) {
						loadTile(tile, __movContent, false);
						tile.state = LOADING_FULL;
					} else if(tile.state < LOADING_PREVIEW && tile.previewStart > 0 && __movContent.length >= (tile.previewStart + tile.previewLength)) {
						loadTile(tile, __movContent, true);
						tile.state = LOADING_PREVIEW;
					}
				}
			}
		}

		private function loadTile(__tile:Object, __movContent:ByteArray, __preview:Boolean):void {
			// load tile jpeg data into ByteArray;
			var content:ByteArray = new ByteArray();
			__movContent.position = (__preview)? __tile.previewStart : __tile.start;
			__movContent.readBytes(content, 0, (__preview)? __tile.previewLength : __tile.length);

			// load ByteArray into Loader;
			var loader:Loader = new Loader();
			loader.loadBytes(content);
			loader.contentLoaderInfo.addEventListener(Event.COMPLETE, loadComplete);

			__tile.loader = loader;
		}

		private function loadComplete(__event:Event):void {
			var loaderInfo:LoaderInfo = __event.target as LoaderInfo;
			for each (var tile:Object in tiles) {
				if(tile.loader == loaderInfo.loader) {
					tile.size = loaderInfo.width;

					var bitmap:BitmapData = new BitmapData(tile.size, tile.size);
					bitmap.draw(tile.loader);
					tile.loader.unload();
					tile.loader = null;

					populateSprite(tile.sprite, tile.location, tile.size, bitmap);

					tile.state++;
					break;
				}
			}
		}

		private function populateSprite(__sprite:Sprite, __location:Object, __size:Number, __bitmap:BitmapData):void {
			__sprite.graphics.clear()
			__sprite.graphics.beginBitmapFill(__bitmap, new Matrix(), true, true);
			__sprite.graphics.drawRect( 0, 0, __size, __size);
			__sprite.graphics.endFill();

			__sprite.x = __location.x * __size / 2;
			__sprite.y = __location.y * __size / 2;
			__sprite.z = __location.z * __size / 2;

			seamFix();
		}

		private function draw(__event:Event):void {
			if(!forcedZoom)
				fovSpeed *= 0.8;

			fov *= Math.pow(1.02,fovSpeed);
			fov = Math.min(170, fov);
			fov = Math.min(Math.max(fov, fovLimits.min), fovLimits.max);

			updateFov();
			var _hfov:Number = 2 * Math.atan( (stage.stageWidth/stage.stageHeight) * Math.tan(Math.PI * fov / 360) )*180/Math.PI;

			if(dragging) {
				panSpeed = fov * (mouseLoc.x - dragLoc.x) / (stage.stageWidth * 4);
				tiltSpeed = fov * (mouseLoc.y - dragLoc.y) / (stage.stageHeight * 4);
			} else {
				if (panSpeed!=0)
					panSpeed = Math.floor(panSpeed * 750)/1000;
				if (tiltSpeed!=0)
					tiltSpeed = Math.floor(tiltSpeed * 750)/1000;
			}

			pan -= panSpeed;
			tilt -= tiltSpeed;

			var _panLimits:Object = {min:0, max:0};
			var _tiltLimits:Object = {min:0, max:0};

			if(Math.abs(panLimits.max - panLimits.min) < 360) {
				// limit pan
				_panLimits.max = panLimits.max - _hfov/2;
				_panLimits.min = panLimits.min + _hfov/2;

				pan = Math.min(Math.max(pan, _panLimits.min), _panLimits.max);
			}

			_tiltLimits.max = (tiltLimits.max >= 90) ? 90 : tiltLimits.max - fov/2;
			_tiltLimits.min = (tiltLimits.min <= -90) ? -90 : tiltLimits.min + fov/2;

			tilt = Math.min(Math.max(tilt, _tiltLimits.min), _tiltLimits.max);


			camera.rotationY = pan;
			this.rotationX = -tilt;
		}

		private function resize(__event:Event):void {
			var center:Point = new Point( (stage.stageWidth/2), (stage.stageHeight/2) );
			parent.transform.perspectiveProjection.projectionCenter = center;
			this.x = center.x;
			this.y = center.y;

			updateFov();
		}

		private function updateFov():void {
			// todo: find out if the 240 constant is right...
			var _fov:Number = 2 * Math.atan((240/stage.stageHeight) * (2 * Math.tan((Math.PI*fov/180) /2)) )*180/Math.PI;
			if(parent.transform.perspectiveProjection.fieldOfView != _fov && (_fov>0 && _fov<180)) {
				parent.transform.perspectiveProjection.fieldOfView = _fov;
				this.z = -(parent.transform.perspectiveProjection.focalLength);

				seamFix();
			}
		}

		private function seamFix():void {
			var size:Number = 0;
			var fix:Number = 0;
			for each (var tile:Object in tiles) {
				// somewhat nasty workaround for seams between sprites
				if(tile.size!=size) {
					size = tile.size
					fix = Math.tan(Math.PI * fov / 360) * (4/tile.size) * (480/stage.stageHeight);
				}
				
				tile.sprite.scaleX = 1 + fix;
				tile.sprite.scaleY = 1 + fix;
			}
		}

		private function mouseMove(__event:MouseEvent):void {
			mouseLoc = new Point(__event.stageX, __event.stageY);
			if(dragging==true && !__event.buttonDown)
				dragEnd(__event);
		}

		private function dragStart(__event:MouseEvent):void {
			dragging = true;
			dragLoc = new Point(__event.stageX, __event.stageY);
		}

		private function dragEnd(__event:MouseEvent):void {
			dragging = false;
		}

		private function keyDown(__event:KeyboardEvent):void {
			if (__event.keyCode == Keyboard.SHIFT || __event.keyCode == Keyboard.CONTROL) {
				fovSpeed = (__event.keyCode==Keyboard.SHIFT)? -1 : 1;
				forcedZoom = true;
			}
		}
		private function keyUp(__event:KeyboardEvent):void {
			if (__event.keyCode == Keyboard.SHIFT || __event.keyCode == Keyboard.CONTROL) {
				forcedZoom = false;
			}
		}

		private function sendLog(__message:String, __type:String):void {
			message = __message;
			this.eventDispatcher.dispatchEvent(new Event(__type));
		}
	}
}