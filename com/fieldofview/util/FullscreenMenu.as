package com.fieldofview.util {
	import flash.ui.ContextMenu;
	import flash.ui.ContextMenuItem;
	import flash.display.*;
	import flash.events.*;

//	import flash.external.ExternalInterface;
	
	public class FullscreenMenu {
		private var contextMenu:ContextMenu;
		private var customItem:ContextMenuItem;
		private var stage:Stage;

		public function FullscreenMenu(__parent:Sprite):void {
			contextMenu = new ContextMenu();
			contextMenu.addEventListener(ContextMenuEvent.MENU_SELECT, menuHandler);
			contextMenu.hideBuiltInItems();
			
			customItem = new ContextMenuItem("Fullscreen" );
			customItem.addEventListener(ContextMenuEvent.MENU_ITEM_SELECT, goFullScreen);
			contextMenu.customItems.push( customItem );
			customItem = new ContextMenuItem("Exit fullscreen" );
			customItem.addEventListener(ContextMenuEvent.MENU_ITEM_SELECT, exitFullScreen);
			contextMenu.customItems.push( customItem );
			
			__parent.contextMenu = contextMenu;
			stage = __parent.stage;
			
//			ExternalInterface.addCallback("setFullscreen", fullScreen);
		}
/*		
		public function fullScreen(__value:Boolean):void {
			if(__value) 
				stage.displayState = StageDisplayState.FULL_SCREEN;
			else
				stage.displayState = StageDisplayState.NORMAL;
		}
*/		
		// functions to enter and leave full screen mode
		private function goFullScreen(event:ContextMenuEvent):void{
			stage.displayState = StageDisplayState.FULL_SCREEN;
		}
		private function exitFullScreen(event:ContextMenuEvent):void{
			stage.displayState = StageDisplayState.NORMAL;
		}
		
		// function to enable and disable the context menu items,
		// based on what mode we are in.
		private function menuHandler(event:ContextMenuEvent):void{
			if (stage.displayState == StageDisplayState.NORMAL){
				event.target.customItems[0].visible = true;
				event.target.customItems[1].visible = false;
			}
			else{
				event.target.customItems[0].visible = false;
				event.target.customItems[1].visible = true;
			}
		}


	}
}