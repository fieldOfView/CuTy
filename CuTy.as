package {
	import flash.display.*;
	import flash.events.*;
	import flash.system.Capabilities;
	import flash.system.Security;

	import com.fieldofview.util.Logger;
	import com.fieldofview.util.FileStreamer;
	import com.fieldofview.util.FullscreenMenu;
	import com.fieldofview.qtparser.QTAtom;
	import com.fieldofview.qtparser.MovParser;

	import com.fieldofview.cuty.CutyScene;

	// SWF Metadata
	[SWF(width="480", height="360", backgroundColor="#FFFFFF", framerate="24")]

	public class CuTy extends Sprite {
		private var logger:Logger;
		private var movStream:FileStreamer;
		private var movStructure:MovParser;
		private var scene:CutyScene;

		public function CuTy() {
			stage.scaleMode = StageScaleMode.NO_SCALE;
			stage.align = StageAlign.TOP_LEFT;

			Security.allowDomain("*")

			logger = new Logger(this);
			logger.send("CuTy 0.1, © Aldo Hoeben / fieldOfView", Logger.INFO);

			// Get the player’s version by using the flash.system.Capabilities class.
			var versionString:String = Capabilities.version.split(",")[0];
			if (parseInt(Capabilities.version.split(",")[0].split(" ")[1]) < 10) {
				logger.send("This viewer requires Flash player 10 or newer", Logger.ERROR);
				return;
			}

			var fullscreenMenu:FullscreenMenu = new FullscreenMenu(this);

			scene = new CutyScene(this);
			scene.eventDispatcher.addEventListener(CutyScene.ERROR, sceneLog);
			scene.eventDispatcher.addEventListener(CutyScene.INFO, sceneLog);

			var movURL:String;
			if (loaderInfo.parameters.hasOwnProperty("mov")) {
				// Get mov url from FlashVars or querystring
				movURL = loaderInfo.parameters["mov"];
			} else {
				// If mov parameter not supplied, try name of swf file with .mov extension
				movURL = loaderInfo.loaderURL.replace(/.swf$/, ".mov");
			}
			logger.send("Loading " + movURL + "...", Logger.INFO);

			movStream = new FileStreamer(movURL);
			movStream.eventDispatcher.addEventListener(FileStreamer.PROGRESS, streamProgress);
			movStream.eventDispatcher.addEventListener(FileStreamer.ERROR, streamError);
			movStream.eventDispatcher.addEventListener(FileStreamer.COMPLETE, streamComplete);

			movStructure = new MovParser(movStream.content);
			movStructure.eventDispatcher.addEventListener(MovParser.ERROR, parserLog);
			movStructure.eventDispatcher.addEventListener(MovParser.INFO, parserLog);
		}

		public function destroy():void {
			if (movStream != null) {
				movStream.destroy();
				movStream = null;
			}

			if (movStructure != null)
				movStructure = null;
		}

		private function parserLog(__event:Event):void {
			logger.send(movStructure.message, __event.type)
			if(__event.type == MovParser.ERROR) {
				destroy();
			}
		}

		private function sceneLog(__event:Event):void {
			logger.send(scene.message, __event.type)
			if(__event.type == CutyScene.ERROR) {
				destroy();
			}
		}


		private function streamProgress(__event:Event):Boolean {
			//logger.send("Progress: " + movStream.bytesLoaded.toString() + " of " + movStream.bytesTotal.toString() + 
			//	" (" + Math.round(100 * movStream.bytesLoaded / movStream.bytesTotal).toString() + "%)", Logger.INFO);
			
			if(!movStructure.allDone) {
				if(!movStructure.handleStream()) {
					return false;
				}
			}

			if(!movStructure.allDone) {
				return false;
			}

			if(!scene.built) {
				scene.build(movStructure);
				logger.send("Loading tiles from Quicktime file...", Logger.INFO);
			}
			if(!scene.allDone) {
				// tiles streaming in
				scene.updateTiles(movStream.content);
			}

			return true;

		}

		private function streamError(__event:Event):void {
			logger.send(movStream.error, Logger.ERROR);
			destroy();
		}

		private function streamComplete(__event:Event):void {
			if(movStructure != null && movStructure.allDone == false) {
				logger.send("Unexpected end of file.", Logger.ERROR);
				destroy();
			}
			logger.send("Done", Logger.INFO);
		}
	}
}