package com.fieldofview.util {
	import flash.text.*;
	import flash.display.Sprite;
	import flash.events.*;
	import flash.ui.Keyboard;

	public class Logger extends Sprite {
		public static var INFO:String = "info";
		public static var ERROR:String = "error";

		private var logText:TextField;

		public function Logger(__parent:Sprite):void {
			__parent.addChild(this);
			this.visible = false;

			logText = new TextField();
			logText.wordWrap = true;
			logText.background = true;
			logText.autoSize = TextFieldAutoSize.LEFT;

			logText.width = stage.stageWidth/2;

			var textFormat:TextFormat = new TextFormat();
			textFormat.font = "Tahoma";
			textFormat.size = 10;
			logText.defaultTextFormat = textFormat;

			this.addChild(logText);

			stage.addEventListener(KeyboardEvent.KEY_DOWN, keyDown);
		}
		
		public function send(__message:String, __type:String):void {
			if(__type == ERROR) {
				__message = "Error: " + __message;
				this.visible = true;
			}

			logText.appendText(__message + "\n");
			trace(__message);
		}

		private function keyDown(__event:KeyboardEvent):void {
			if (__event.keyCode == Keyboard.SPACE && __event.shiftKey == true) {
				this.visible = !this.visible;
			}
		}
	}
}