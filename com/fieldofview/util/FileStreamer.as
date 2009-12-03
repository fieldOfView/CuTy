package com.fieldofview.util {
	import flash.events.*;

	import flash.errors.*;
	import flash.net.URLRequest;
	import flash.net.URLStream;
	import flash.utils.ByteArray;

	public class FileStreamer {
		public var content:ByteArray;
		public var isActive:Boolean = false;

		public var bytesLoaded:uint;
		public var bytesTotal:uint;

		public var error:String;
		public var httpStatus:uint;

		public var eventDispatcher:EventDispatcher = new EventDispatcher();
		public static var ERROR:String = "error";
		public static var PROGRESS:String = "progress";
		public static var COMPLETE:String = "complete";

		private var stream:URLStream;
		
		public function FileStreamer (__url:String) {
			content = new ByteArray();
			stream = new URLStream();

			configureListeners(this.stream);

			try {
				stream.load(new URLRequest(__url));
			} catch (error:Error) {
				stream = null;
				this.error = "Unable to load requested URL; " + error.message;
				eventDispatcher.dispatchEvent(new Event(ERROR));

				destroy();
			}
		}

		public function destroy():void {
			if(stream) {
				stream.close();
				stream = null;
				isActive = false;
			}
		}

		private function configureListeners(dispatcher:EventDispatcher):void {
			dispatcher.addEventListener(Event.OPEN, openHandler);
			dispatcher.addEventListener(Event.COMPLETE, completeHandler);
			dispatcher.addEventListener(ProgressEvent.PROGRESS, progressHandler);
			dispatcher.addEventListener(HTTPStatusEvent.HTTP_STATUS, httpStatusHandler);
			dispatcher.addEventListener(SecurityErrorEvent.SECURITY_ERROR, errorHandler);
			dispatcher.addEventListener(IOErrorEvent.IO_ERROR, errorHandler);
		}


		private function openHandler(__event:Event):void {
			isActive = true;
		}

		private function progressHandler(__event:ProgressEvent):void {
			if ( this.stream.bytesAvailable > 0 ) {
				var _buffer:ByteArray = new ByteArray();
				// read newly received bytes from stream
				stream.readBytes(_buffer);

				// reset position to the end of the ByteArray and append the bytes we just got.
				content.position = this.content.length;
				content.writeBytes(_buffer);
			}

			if ( __event.bytesLoaded > this.bytesLoaded) {
				bytesLoaded = __event.bytesLoaded;
				bytesTotal = __event.bytesTotal;

				eventDispatcher.dispatchEvent(new Event(PROGRESS));
			}
		}

		private function completeHandler(__event:Event):void {
			//trace("File complete");
			isActive = false;
			stream = null;

			eventDispatcher.dispatchEvent(new Event(COMPLETE));
		}

		private function httpStatusHandler(__event:HTTPStatusEvent):void {
			//trace("HTTP status: " + __event.status.toString());

			httpStatus = __event.status;
		}

		private function errorHandler(__event:IOErrorEvent):void {
			//trace(__event.text);

			this.error = __event.text;
			eventDispatcher.dispatchEvent(new Event(ERROR));

			destroy()
		}
	}
}