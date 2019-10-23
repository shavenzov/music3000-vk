package
{
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.events.ContextMenuEvent;
	import flash.events.ErrorEvent;
	import flash.events.Event;
	import flash.events.ProgressEvent;
	import flash.net.URLRequest;
	import flash.net.navigateToURL;
	import flash.ui.ContextMenu;
	import flash.ui.ContextMenuItem;
	
	import mx.core.FlexGlobals;
	import mx.preloaders.SparkDownloadProgressBar;
	
	import classes.api.MainAPI;
	import classes.api.social.vk.VKApi;
	import classes.tasks.initilization.InitializationTask;
	
	public class MainPreloader extends SparkDownloadProgressBar
	{
		[Embed(source="/assets/assets.swf", symbol="preloader_bg")]
		private static const BGClass : Class;
		
		private var fill : Shape;
		private var bg : Sprite;
		private var p : SplashPreloader;
		
		private var initTask : InitializationTask;
		
		private var cmItem : ContextMenuItem;
		
		public function MainPreloader()
		{
			super();
			addEventListener( Event.ADDED_TO_STAGE, onAddedToStage );
			addEventListener( Event.REMOVED_FROM_STAGE, onRemovedFromStage );
			createChildren();
			
			//ExternalInterface.call( 'IFlash.swfLoaded' );
		}
		
		private function onAddedToStage( e : Event ) : void
		{
			SWFWheel.initialize( stage ); //Поддержка события колесика мышки в разных браузерах
			SWFWheel.browserScroll = false;
			
			removeEventListener( Event.ADDED_TO_STAGE, onAddedToStage );
			stage.addEventListener( Event.RESIZE, onResize );
			updateDisplayList( stage.stageWidth, stage.stageHeight );
		}
		
		/**
		 * Добавляет информацию о версии приложения в контекстное меню на время загрузки 
		 * 
		 */		
		private function addMenuItems() : void
		{
			contextMenu = new ContextMenu();
			contextMenu.hideBuiltInItems();
			contextMenu.customItems.push( cmItem );
		}
		
		/**
		 * Добавляет информацию о версии приложения в контекстное меню для всего приложения
		 * 
		 */
		private function addGlobalMenuItems() : void
		{
			FlexGlobals.topLevelApplication.contextMenu.hideBuiltInItems();
			FlexGlobals.topLevelApplication.contextMenu.customItems.push( cmItem );
		}
		
		private function onRemovedFromStage( e : Event ) : void
		{
			removeEventListener( Event.REMOVED_FROM_STAGE, onRemovedFromStage );
			stage.removeEventListener( Event.RESIZE, onResize );
		}
		
		private function onResize( e : Event ) : void
		{
			updateDisplayList( stage.stageWidth, stage.stageHeight );
		}
		
		private function loadSettings() : void
		{
			initTask = new InitializationTask( stage );
			initTask.addEventListener( ErrorEvent.ERROR, onErrorInit );
			initTask.addEventListener( Event.COMPLETE, onInitComplete );
			initTask.run();
		}
		
		private function clearInitTask() : void
		{
			initTask.removeEventListener( ErrorEvent.ERROR, onErrorInit );
			initTask.removeEventListener( Event.COMPLETE, onInitComplete );
			initTask = null;
		}
		
		private function onErrorInit( e : ErrorEvent ) : void
		{
			p.scaleX = 2;
			p.scaleY = 2;
			
			if ( e.errorID == 15900 )
			{
				p.showError2();
				return;
			}
			
			p.showError();
		}
		
		private function onInitComplete( e : Event ) : void
		{
			clearInitTask();
			
			/*if ( MainAPI.impl.userInfo.pro || MainAPI.impl.firstTime || VKApi.userInfo.uid == '0' )
			{*/
				dispatchEvent( new Event( Event.COMPLETE ) );
				/*return;
			}
			
			showVKAds();*/
		}
		
		private var ads : VKPrerollAd;
		
		private function showVKAds() : void
		{
			ads = new VKPrerollAd();
			ads.addEventListener( Event.COMPLETE, onAdsComplete );
			ads.addEventListener( ErrorEvent.ERROR, onAdsError );
			ads.initialize( stage );
		}
		
		private function onAdsComplete( e : Event ) : void
		{
			hideVKAds();
		}
		
		private function onAdsError( e : ErrorEvent ) : void
		{
			hideVKAds();
		}
		
		private function hideVKAds() : void
		{
			ads.removeEventListener( Event.COMPLETE, onAdsComplete );
			ads.removeEventListener( ErrorEvent.ERROR, onAdsError );
			
			ads = null;
			dispatchEvent( new Event( Event.COMPLETE ) );
		}
		
		override protected function initCompleteHandler(event:Event):void
		{
			p.text = 'Секундочку';
			addGlobalMenuItems();
			loadSettings();
		}	
		
		override protected function progressHandler(event:ProgressEvent):void
		{
			p.drawPercent( event.bytesLoaded / event.bytesTotal );
		}
		
		override protected function initProgressHandler(event:Event):void
		{
			
		}
		
		override protected function setInitProgress(completed:Number, total:Number):void
		{
			
		}
		
		private static function onContextMenuItemSelect( e : ContextMenuEvent ) : void
		{
			navigateToURL( new URLRequest( Settings.APPLICATION_SUPPORT ) );
		}
		
		override protected function createChildren():void
		{
			cmItem = new ContextMenuItem( Settings.APPLICATION_NAME + ' v.' + BUILD.VERSION );
			cmItem.addEventListener( ContextMenuEvent.MENU_ITEM_SELECT, onContextMenuItemSelect );
			addMenuItems();
			
			fill = new Shape();
			fill.graphics.beginFill( 0x000000 );
			fill.graphics.drawRect( 0, 0, 10, 10 );
			fill.graphics.endFill();
			
			bg = new BGClass();
			p = new SplashPreloader();
			p.scaleX = 3;
			p.scaleY = 3;
			
			addChild( fill );
			addChild( bg );
			addChild( p );
		}
		
		private function updateDisplayList( w : Number, h : Number ) : void
		{
			fill.width = w;
			fill.height = h;
			bg.x = ( w - bg.width ) / 2;
			bg.y = ( h - bg.height ) / 2;
			p.x = w /2;
			p.y = h / 2;
		}
	}
}