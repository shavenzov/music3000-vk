/**
 * Created by IntelliJ IDEA.
 * User: light
 * Date: 3/26/12
 * Time: 1:03 PM
 * To change this template use File | Settings | File Templates.
 */
package {
import flash.display.DisplayObjectContainer;
import flash.display.Loader;
import flash.display.Sprite;
import flash.display.Stage;
import flash.events.ErrorEvent;
import flash.events.Event;
import flash.events.EventDispatcher;
import flash.events.IOErrorEvent;
import flash.events.SecurityErrorEvent;
import flash.events.UncaughtErrorEvent;
import flash.media.SoundMixer;
import flash.media.SoundTransform;
import flash.net.URLRequest;
import flash.net.URLVariables;
import flash.system.ApplicationDomain;
import flash.system.LoaderContext;
import flash.system.Security;
import flash.system.SecurityDomain;
import flash.system.System;
import flash.utils.clearTimeout;
import flash.utils.setTimeout;

public class CMPrerollVk extends EventDispatcher {
	public var cmFlashUrl:String = "http://img.creara-media.ru/lembrd/cm_1.0.swf";
	/**
	 * Подложка рекламного блока
	 */
	private var cmOverlay:Sprite = new Sprite();
	/**
	 * Загрузчик рекламного блока
	 */
	private var cmPrerollLoader:Loader;

	/**
	 * визуальный контейнер рекламного блока
	 */
	private var cmPreroll:Object;
//	private var flashVars:Object;

	private var pid:Number = 0;

	public var ext:* = {};

	private var rootContainer:DisplayObjectContainer;

	private var params:Object = {};
	
	private var soundVolume : Number;
	private var soundPan    : Number;

	public function CMPrerollVk(pid:Number, rootContainer:DisplayObjectContainer) {
		
		soundVolume = SoundMixer.soundTransform.volume;
		soundPan    = SoundMixer.soundTransform.pan;
		
		cmOverlay.visible = false;
		Security.allowDomain( "*" );
		Security.allowInsecureDomain( "*" );

		this.pid = pid;
		this.rootContainer = rootContainer;

//		this.flashVars = rootContainer.loaderInfo.parameters;

		this.cmPrerollLoader = new Loader();

		this.cmPrerollLoader.contentLoaderInfo.addEventListener( IOErrorEvent.IO_ERROR, onError );
		this.cmPrerollLoader.contentLoaderInfo.addEventListener( Event.COMPLETE, onLoaded );
		this.cmPrerollLoader.contentLoaderInfo.addEventListener( IOErrorEvent.NETWORK_ERROR, onError );
		this.cmPrerollLoader.contentLoaderInfo.addEventListener( SecurityErrorEvent.SECURITY_ERROR, onError );
	}

	private function cmRedrawOverlay():void {
		cmOverlay.graphics.clear();
		if ( stage == null )
			return;

		cmOverlay.graphics.beginFill( 0xF7F7F7 );
		cmOverlay.graphics.drawRect( 0, 0, stage.stageWidth, stage.stageHeight );
		cmOverlay.graphics.endFill();
	}

	private function get stage():Stage {
		return rootContainer.stage;
	}


	private function onLoaded(event:Event):void {
		try {
			cmPreroll = cmPrerollLoader.content;

			cmPrerollLoader.contentLoaderInfo.uncaughtErrorEvents.addEventListener( UncaughtErrorEvent.UNCAUGHT_ERROR, onUncaughtErrors );
			
			cmPrerollLoader.contentLoaderInfo.sharedEvents.addEventListener( "cmShowBanner", onShowBanner );
			cmPrerollLoader.contentLoaderInfo.sharedEvents.addEventListener( "cmHideBanner", onHideBanner );
			cmPrerollLoader.contentLoaderInfo.sharedEvents.addEventListener( "cmNothingToRotate", onNothingToRotate );
			
			cmPreroll.initialize( 0, rootContainer, {} );


		} catch( e:Error ) {
			trace( "Init failed", e );
			dispatchEvent( new ErrorEvent( ErrorEvent.ERROR, false, false, e.message, e.errorID ) );
		}
	}
	
	private function onNothingToRotate( e : Event ) : void
	{
		/*
		Отключаем таймер
		*/
		unwait();
		
		releaseCreara();
		dispatchEvent( e );
	}

	private function releaseCreara() : void
	{
		cmOverlay.visible = false;
		stage.removeEventListener( "resize", onStageResize );
		stage.removeEventListener( "added", onChildAdded );
		
		rootContainer.removeEventListener( Event.ADDED_TO_STAGE, cmOnAddedToStage );
		
		if ( rootContainer.contains( cmOverlay ) )
			rootContainer.removeChild( cmOverlay );
		
		if ( this.cmPrerollLoader != null ) {
			
			cmPrerollLoader.contentLoaderInfo.uncaughtErrorEvents.removeEventListener( UncaughtErrorEvent.UNCAUGHT_ERROR, onUncaughtErrors );
			
			cmPrerollLoader.contentLoaderInfo.sharedEvents.removeEventListener( "cmShowBanner", onShowBanner );
			cmPrerollLoader.contentLoaderInfo.sharedEvents.removeEventListener( "cmHideBanner", onHideBanner );
			cmPrerollLoader.contentLoaderInfo.sharedEvents.removeEventListener( "cmNothingToRotate", onNothingToRotate );
			
			if ( rootContainer.contains( cmPrerollLoader ) )
				rootContainer.removeChild( cmPrerollLoader );
			
			if ( cmPreroll != null )
				cmPreroll.dispose();
			
			cmPrerollLoader.unload();
			cmPrerollLoader = null;
			cmPreroll = null;
			cmOverlay = null;
			rootContainer = null;
			System.gc();
		}
		
		SoundMixer.soundTransform = new SoundTransform( soundVolume, soundPan );
	}
	
	private function onHideBanner(event:Event):void {

		trace( "[CM] HIDE banner" );
		releaseCreara();
		dispatchEvent( event );
	}

	private function onUncaughtErrors( event : UncaughtErrorEvent ) : void
	{
		var message:String;
		
		/*
		Отключаем таймер
		*/
		unwait();
		
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
		
		releaseCreara();
		dispatchEvent( new ErrorEvent( ErrorEvent.ERROR, false, false, message, event.error.errorID ) );
	}
	
	private function onError(event:Event):void {
		releaseCreara();
		dispatchEvent( new ErrorEvent( ErrorEvent.ERROR, false, false, 'Error loading preroll', 100 ) );
	}
    
	/**
	 * Время ожидания загрузки банера, если это время истечет, то реклама автоматически закроется 
	 */	
    private static const LOADING_WAIT_TIME : Number = 15000.0;
	
	private var timeout_id : int; 
	
	public function initCreara(fv:*):CMPrerollVk
	{
        wait();
		
		this.params = fv;

		if ( stage == null ) {
			rootContainer.addEventListener( Event.ADDED_TO_STAGE, cmOnAddedToStage );
		} else {
			cmOnAddedToStage( null );
		}

		return this;
	}
	
	private function wait() : void
	{
		if ( timeout_id == -1 )
		{
			timeout_id = setTimeout( onLoadingWaitTimeExpired, LOADING_WAIT_TIME );
		}
	}
	
	private function unwait() : void
	{
		if ( timeout_id != -1 )
		{
			clearTimeout( timeout_id );
			timeout_id = -1;
		}
	}
	
	private function onLoadingWaitTimeExpired() : void
	{
		onNothingToRotate( new Event( 'cmNothingToRotate' ) );
	}

	private function cmOnAddedToStage(event:*):void {

		try {
			if ( event != null ) {
				rootContainer.removeEventListener( Event.ADDED_TO_STAGE, cmOnAddedToStage );
			}

			cmRedrawOverlay();
			rootContainer.addChild( cmOverlay );

			stage.addEventListener( "resize", onStageResize );
			stage.addEventListener( "added", onChildAdded );

			/// load
			var req:URLRequest = new URLRequest( cmFlashUrl );
			var reqParams:URLVariables = new URLVariables();
			setup( params, reqParams, ['viewer_id', 'api_id', 'secret', 'sid'] );
			setup( ext, reqParams, ext );

			reqParams['pid'] = pid + "";

			req.data = reqParams;
			var lc:LoaderContext = new LoaderContext( true,
					ApplicationDomain.currentDomain,
					SecurityDomain.currentDomain );

			cmPrerollLoader.load( req, lc );

			rootContainer.addChild(cmPrerollLoader);
			cmPrerollLoader.visible = false;

		} catch( e:Error ) {
			trace( "[CM] Failed", e.getStackTrace() );
		}

	}

	private function onChildAdded(event:Event):void {
		if ( cmOverlay != null && rootContainer.contains( cmOverlay ) ) {
			rootContainer.setChildIndex( cmOverlay, rootContainer.numChildren - 1 );
		}

		if ( cmPrerollLoader != null && rootContainer.contains( cmPrerollLoader ) ) {
			rootContainer.setChildIndex( cmPrerollLoader, rootContainer.numChildren - 1 );
		}
	}

	private function onStageResize(event:Event):void {
		setupAndShowBanner();
	}

	private function onShowBanner(event:Event):void {
		
		/*
		Отключаем таймер
		*/
		unwait();
		
		cmOverlay.visible = true;
		setupAndShowBanner();
		dispatchEvent( event );
	}

	private function setupAndShowBanner():void {
		cmRedrawOverlay();
		if ( stage != null && cmPreroll != null ) {
			var w:int = stage.stageWidth;
			var h:int = stage.stageHeight;

			if ( w == 0 || h == 0 )
				return;

			cmPrerollLoader.visible = true;
			center( cmPreroll, w, h );
		}
	}

	public function center(preroll:Object, w:int, h:int):void {
		preroll.x = (w - 500) / 2;
		preroll.y = 50;
	}

	private function setup(o:*, t:*, args:*):void {
		if ( args is Array ) {
			for each( var a:String in args ) {
				if ( a in o && o[a] != null ) {
					t[a] = o[a];
				}
			}
		} else {
			for ( var b:String in args ) {
				if ( b in o && o[b] != null ) {
					t[b] = o[b];
				}
			}
		}
	}

}
}
