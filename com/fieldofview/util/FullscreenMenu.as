package com.fieldofview.util {
	import flash.ui.ContextMenu;
	import flash.ui.ContextMenuItem;
	import flash.display.*;
	import flash.events.*;
	import flash.utils.getTimer;

	public class FullscreenMenu {
		private var contextMenu:ContextMenu;
		private var customItem:ContextMenuItem;
		private var stage:Stage;
		
		private var lastClickTime:int;

		public function FullscreenMenu(__parent:Sprite):void {
			contextMenu = new ContextMenu();
			contextMenu.addEventListener(ContextMenuEvent.MENU_SELECT, menuHandler);
			contextMenu.hideBuiltInItems();
			
			customItem = new ContextMenuItem("Fullscreen" );
			customItem.addEventListener(ContextMenuEvent.MENU_ITEM_SELECT, contextMenuItemHandler);
			contextMenu.customItems.push( customItem );
			customItem = new ContextMenuItem("Exit fullscreen" );
			customItem.addEventListener(ContextMenuEvent.MENU_ITEM_SELECT, contextMenuItemHandler);
			contextMenu.customItems.push( customItem );
			
			__parent.contextMenu = contextMenu;
			
			stage = __parent.stage;
			// We can't use MouseEvent.DOUBLE_CLICK, as that requires stage.mouseChildren = false;
			// When stage.mouseChildren = false, the contextMenu does not work.
			stage.addEventListener(MouseEvent.CLICK, clickHandler);
		}

		private function contextMenuItemHandler(event:ContextMenuEvent):void {
            toggleFullScreen();
        }
		
		private function clickHandler(event:MouseEvent):void {
			var currentTime:int = getTimer();
			if(currentTime - lastClickTime < 250) {
				toggleFullScreen();
			}
			lastClickTime = currentTime;
		}

		private function toggleFullScreen():void {
			stage.displayState = (stage.displayState==StageDisplayState.NORMAL)?StageDisplayState.FULL_SCREEN:StageDisplayState.NORMAL;
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