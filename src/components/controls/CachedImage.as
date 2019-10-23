package components.controls
{
	import com.dataloaders.GlobalImageCash;
	import com.dataloaders.ImageCash;
	
	import components.sequencer.timeline.visual_sample.Preloader;
	
	import flash.display.DisplayObject;
	import flash.display.Loader;
	import flash.display.Shape;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.ProgressEvent;
	import flash.events.SecurityErrorEvent;
	
	import mx.core.UIComponent;
	
	public class CachedImage extends UIComponent
	{
		private var imageCash : ImageCash;
		
		private var _url      : String;
		private var preloader : Preloader;
		protected var image     : DisplayObject;
		
		private var loader : Loader;
		
		public function CachedImage() : void
		{
			super();
			imageCash = GlobalImageCash.impl;
		}
		
		public function get url() : String
		{
			return _url;
		}
		
		public function set url( value : String ) : void
		{
			if ( value == _url )
			{
				return;
			}
			
			_url = value;
			
			unsetLoaderListeners();
			
			if ( image )
			{
				removeChild( image );
				image = null;
			}
			
			if ( preloader )
			{
				removeChild( preloader );
				preloader = null;
			}
			
			if ( _url )
			{
				if ( imageCash.imageIsLoaded( _url ) )
				{
					image = imageCash.getClonedImage( _url );
					addChildAt( image, 0 );
				}
				else
				{
					loader = imageCash.getImage( _url );
					setLoaderListeners();
					if ( ! image )
					{
						preloader = new Preloader();
						addChildAt( preloader, 0 );
						invalidateDisplayList();
					}
				}
			}
		}
		
		private function setLoaderListeners() : void
		{
			if ( loader )
			{
				loader.contentLoaderInfo.addEventListener( ProgressEvent.PROGRESS, onProgress );
				loader.contentLoaderInfo.addEventListener( Event.COMPLETE, onComplete );
				loader.contentLoaderInfo.addEventListener( IOErrorEvent.IO_ERROR, onComplete );
				loader.contentLoaderInfo.addEventListener( SecurityErrorEvent.SECURITY_ERROR, onComplete );
			}
		}
		
		private function unsetLoaderListeners() : void
		{
			if ( loader )
			{
				loader.contentLoaderInfo.removeEventListener( ProgressEvent.PROGRESS, onProgress );
				loader.contentLoaderInfo.removeEventListener( Event.COMPLETE, onComplete );
				loader.contentLoaderInfo.removeEventListener( IOErrorEvent.IO_ERROR, onComplete );
				loader.contentLoaderInfo.removeEventListener( SecurityErrorEvent.SECURITY_ERROR, onComplete );
				
				loader = null;  
			}
		}
		
		private function onProgress( e : ProgressEvent ) : void
		{
			preloader.setProgress( e.bytesLoaded, e.bytesTotal );
		}
		
		protected function getDummyImage() : DisplayObject
		{
			var s : Shape = new Shape();
			    s.graphics.beginFill( 0x00fff00 );
				s.graphics.drawRect( 0, 0, 1, 1 );
				s.graphics.endFill();
				
				s.width = 50;
				s.height = 50;
				
			return s;	
		}
		
		private function onComplete( e : Event ) : void
		{
			unsetLoaderListeners();
			
			if ( preloader )
			{
				removeChild( preloader );
				preloader = null;
			}
			
			if ( e.type == Event.COMPLETE )
			{
				image = imageCash.getClonedImage( url );	
			}
			else
			{
				image = getDummyImage();
			}
			
			addChildAt( image, 0 );
			invalidateSize();
		}
		/*
		private function onIOError( e : IOErrorEvent ) : void
		{
			unsetLoaderListeners();
			trace( e.text );
		}
		
		private function onSecurityError( e : SecurityErrorEvent ) : void
		{
			unsetLoaderListeners();
		}
		*/
		override protected function measure():void
		{
			if ( preloader )
			{
				measuredWidth  = 48;
				measuredHeight = 48;
			}
			
			if ( image )
			{
				measuredWidth = image.width;
				measuredHeight = image.height;
			}
			
			measuredMinWidth  = measuredWidth;
			measuredMinHeight = measuredHeight;
		}
		
		override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void
		{
			if ( preloader )
			{
				preloader.touch();
				preloader.x = ( unscaledWidth - preloader.contentWidth ) / 2;
				preloader.y = ( unscaledHeight - preloader.contentHeight ) / 2;
			}
		}
		
		
	}
}