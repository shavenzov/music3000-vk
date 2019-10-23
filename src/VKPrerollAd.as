package
{
	import flash.display.DisplayObject;
	import flash.display.Loader;
	import flash.display.Stage;
	import flash.events.ErrorEvent;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IOErrorEvent;
	import flash.events.SecurityErrorEvent;
	import flash.events.UncaughtErrorEvent;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.system.ApplicationDomain;
	import flash.system.Capabilities;
	import flash.system.LoaderContext;
	import flash.system.Security;
	import flash.system.System;
	
	public class VKPrerollAd extends EventDispatcher
	{
		private var loader  : Loader;
		private var counter : URLLoader;
		private var stage   : Stage;
		private var ad      : Object;
		
		public function VKPrerollAd()
		{
			super();
		}
		
		private static const APP_ID            : String = '3395763';
		private static const COUNTER_URL       : String = '//js.appscentrum.com/';
		private static const AD_LIB_MODULE_URL : String = '//ad.mail.ru/static/vkcontainer.swf';
		
		public function initialize( stage : Stage ) : void
		{
			/*
			В отладочном режиме у рекламы возникает странный глюк 
			Error #2044: Unhandled StatusEvent:. level=error, code=
			Поэтому в отладочном режиме не показываем рекламу и генерируем ошибку
			*/
			if ( Capabilities.isDebugger )
			{
				dispatchEvent( new ErrorEvent( ErrorEvent.ERROR, false, false, 'In debug mode ads not show', 153225 ) );
				return;
			}
			
			this.stage = stage;
			
			Security.allowDomain( "*" );
			Security.allowInsecureDomain( "*" );
			
			var flashVars : Object = stage.loaderInfo.parameters as Object;
			
			counter = new URLLoader();
			counter.addEventListener( Event.COMPLETE, onCounterComplete );
			counter.addEventListener( IOErrorEvent.IO_ERROR, onIOError );
			counter.addEventListener( SecurityErrorEvent.SECURITY_ERROR, onSecurityError );
			
			try
			{
				counter.load(new URLRequest( COUNTER_URL + "s?app_id=" + APP_ID + "&user_id=" + flashVars['viewer_id'] ) );
			}
			catch( error : Error )
			{
				dispatchEvent( new ErrorEvent( ErrorEvent.ERROR, false, false, error.message, error.errorID ) );
			}
		}
		
		private function onIOError( e : IOErrorEvent ) : void
		{
			dispatchEvent( new ErrorEvent( ErrorEvent.ERROR, false, false, e.text, e.errorID ) );
		}
		
		private function onSecurityError( e : SecurityErrorEvent ) : void
		{
			dispatchEvent( new ErrorEvent( ErrorEvent.ERROR, false, false, e.text, e.errorID ) );
		}
		
		private function onCounterComplete( e : Event ) : void
		{
			counter.removeEventListener( Event.COMPLETE, onCounterComplete );
			counter.removeEventListener( IOErrorEvent.IO_ERROR, onIOError );
			counter.removeEventListener( SecurityErrorEvent.SECURITY_ERROR, onSecurityError );
			counter = null;
			
			
			loader = new Loader();
			loader.contentLoaderInfo.addEventListener( Event.COMPLETE, onLoaderComplete );
			loader.contentLoaderInfo.addEventListener( IOErrorEvent.IO_ERROR, onIOError );
			loader.contentLoaderInfo.addEventListener( SecurityErrorEvent.SECURITY_ERROR, onSecurityError );
			
			var context : LoaderContext = new LoaderContext( false, new ApplicationDomain() );
			
			var adrequest     : URLRequest = new URLRequest( AD_LIB_MODULE_URL );
			/*var requestParams : URLVariables = new URLVariables();
			    requestParams['preview'] = '8';
			
				adrequest.data = requestParams;*/
			
		   loader.load(adrequest, context);
		}
		
		private function onLoaderComplete( e : Event ) : void
		{
			loader.contentLoaderInfo.removeEventListener( Event.COMPLETE, onLoaderComplete );
			loader.contentLoaderInfo.removeEventListener( IOErrorEvent.IO_ERROR, onIOError );
			loader.contentLoaderInfo.removeEventListener( SecurityErrorEvent.SECURITY_ERROR, onSecurityError );
			
			ad = loader.content;
			
			loader.contentLoaderInfo.uncaughtErrorEvents.addEventListener( UncaughtErrorEvent.UNCAUGHT_ERROR, onUncaughtErrors );
			
			stage.addChild( DisplayObject( ad ) );
			
			ad.addEventListener( "adReady", onAdOtherEvents );
			ad.addEventListener( "adLoadFailed", onAdOtherEvents );
			ad.addEventListener( "adError", onAdError);
			ad.addEventListener( "adInitFailed", onAdOtherEvents );
			ad.addEventListener( "adStarted", onAdOtherEvents);
			ad.addEventListener( "adStopped", onAdCompleted );
			ad.addEventListener( "adPaused", onAdOtherEvents );
			ad.addEventListener( "adResumed", onAdOtherEvents );
			ad.addEventListener( "adCompleted", onAdCompleted );
			ad.addEventListener( "adClicked", onAdOtherEvents);
			ad.addEventListener( "adBannerStarted", onAdOtherEvents );
			ad.addEventListener( "adBannerStopped", onAdOtherEvents );
			ad.addEventListener( "adBannerCompleted", onAdOtherEvents );
			
			stage.addEventListener( Event.RESIZE, onResize );
			
			onResize();
			
			ad.init( APP_ID, stage );
		}
		
		private function onAdOtherEvents( e : Event ) : void
		{
			trace( e.type );
			
			dispatchEvent( e );
		}
		
		private function onAdError( e : Event ) : void
		{
			uninit();
			
			onAdOtherEvents( e );
			dispatchEvent( new ErrorEvent( ErrorEvent.ERROR, false, false, 'adError', 1000 ) );
		}
		
		private function onAdCompleted( e : Event ) : void
		{
			uninit();
			
			onAdOtherEvents( e );
			dispatchEvent( new Event( Event.COMPLETE ) );
		}
		
		private function uninit() : void
		{
			stage.removeEventListener( Event.RESIZE, onResize );
			
			ad.removeEventListener("adReady", onAdOtherEvents);
			ad.removeEventListener("adLoadFailed", onAdOtherEvents);
			ad.removeEventListener("adError", onAdError);
			ad.removeEventListener("adInitFailed", onAdOtherEvents);
			ad.removeEventListener("adStarted", onAdOtherEvents);
			ad.removeEventListener("adStopped", onAdOtherEvents);
			ad.removeEventListener("adPaused", onAdOtherEvents);
			ad.removeEventListener("adResumed", onAdOtherEvents);
			ad.removeEventListener("adCompleted", onAdCompleted);
			ad.removeEventListener("adClicked", onAdOtherEvents);
			ad.removeEventListener("adBannerStarted", onAdOtherEvents);
			ad.removeEventListener("adBannerStopped", onAdOtherEvents);
			ad.removeEventListener("adBannerCompleted", onAdOtherEvents);
			
			stage.removeChild( DisplayObject( ad ) );
			
			loader.contentLoaderInfo.uncaughtErrorEvents.removeEventListener( UncaughtErrorEvent.UNCAUGHT_ERROR, onUncaughtErrors );
			
			ad = null;
			
	        loader.unload();
			System.gc();
		}
		
		private function onUncaughtErrors( event : UncaughtErrorEvent ) : void
		{
			var message:String;
			
			if ( event.error is Error )
			{
				message = Error( event.error ).message;
			}
			else if ( event.error is ErrorEvent )
			{
				message = ErrorEvent( event.error ).text;
			}
			else
			{
				message = event.error.toString();
			}
			
			event.preventDefault();
			
			uninit();
			
			trace( 'uncaughtError', message, event.error.errorID );
			
			dispatchEvent( new ErrorEvent( ErrorEvent.ERROR, false, false, message, event.error.errorID ) );
		}
		
		private function onResize( e : Event = null ) : void
		{
			ad.setSize( stage.stageWidth, stage.stageHeight );
		}
	}
}