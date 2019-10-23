package components.sequencer.controls
{
	import components.sequencer.controls.navigatorClasses.NavigatorThumb;
	import components.sequencer.controls.navigatorClasses.SamplesView;
	import components.sequencer.timeline.IScale;
	import components.sequencer.timeline.TimeLineParameters;
	
	import flash.events.MouseEvent;
	import flash.geom.Point;
	import flash.ui.Mouse;
	
	import mx.core.UIComponent;
	import mx.events.PropertyChangeEvent;
	import mx.events.ResizeEvent;
	import mx.managers.CursorManager;
	
	import spark.core.IViewport;
	
	public class Navigator extends SamplesView
	{
		private static const NONE         : int = 0;
		private static const MOVE         : int = 1;
		private static const RESIZE_RIGHT : int = 2;
		private static const RESIZE_LEFT  : int = 3;
		
		/**
		 * Параметры для перетаскивания 
		 */		
		private var thumb : NavigatorThumb;
		private var currentAction : int;
		private var offset : Point;
		
		/**
		 * Количество семплов умещаемых в отображаемом окне 
		 */		
		private var samplesPerWindow : Number;
		
		/**
		 * Объект для которого будет осуществляться навигация 
		 */		
		private var _client : IViewport;
		
		public function Navigator()
		{
			super();
		}
		
		public function get client() : IViewport
		{
			return _client;
		}
		
		public function set client( c : IViewport ) : void
		{	
			if ( _client )
			{	
				unsetClient( _client );
			}
			
			setClient( c );
				
			_client = c;
			
			invalidateDisplayList();
		}
		
		private function setClient( c : IViewport ) : void
		{
			c.addEventListener( PropertyChangeEvent.PROPERTY_CHANGE, onClientPropertyChanged );
			c.addEventListener( ResizeEvent.RESIZE, onClientResized );
		}
		
		private function unsetClient( c : IViewport ) : void
		{
			c.removeEventListener( ResizeEvent.RESIZE, onClientResized );
			c.removeEventListener( PropertyChangeEvent.PROPERTY_CHANGE, onClientPropertyChanged );
		}	
		
		private function onClientResized( e : ResizeEvent ) : void
		{	
			var s : IScale = IScale( _client );
			
			samplesPerWindow = _client.width * s.scale;
			
			if ( currentAction == NONE )
			{
				invalidateDisplayList();
			}	
		}
		
		private function onClientPropertyChanged( e : PropertyChangeEvent ) : void
		{
			if ( currentAction == NONE )
			{
				invalidateDisplayList();
			}
		}	
		
		override protected function createChildren():void
		{
			super.createChildren();
			
			thumb = new NavigatorThumb();
			thumb.addEventListener( MouseEvent.MOUSE_DOWN, onThumbMouseDown );
			thumb.addEventListener( MouseEvent.MOUSE_OVER, onThumbMouseOver );
			thumb.addEventListener( MouseEvent.ROLL_OUT, onThumbRollOut );
			
			addChild( thumb );
		}
		
		/**
		 * Текущий индентификатор курсора 
		 */		
		private var cursorID : int = -1;
		
		private function clearCursor() : void
		{
			if ( cursorID != -1 )
			{
				cursorManager.removeCursor( cursorID );
				cursorID = -1;
			}
		}
		
		private function setCursor( cursorClass : Class ) : void
		{
			clearCursor();
			cursorID = CursorManager.setCursor( cursorClass );
		}
		
		private function onThumbMouseOver( e : MouseEvent ) : void
		{
			if ( thumb.mouseDown ) return;
			
			if ( e.target == thumb.toLeftButton )
			{
				setCursor( Assets.RESIZE_CURSOR );
			}
			else if ( e.target == thumb.toRightButton )
			{
				setCursor( Assets.RESIZE_CURSOR );
			}
			else
			{
				setCursor( Assets.HAND_CURSOR );
			}
		}
		
		private function onThumbRollOut( e : MouseEvent ) : void
		{
			if ( thumb.mouseDown ) return;
			clearCursor();
		}
		
		private function onThumbMouseDown( e : MouseEvent ) : void
		{
			if ( ! _client )
			{
				return;
			}	
			
			stage.addEventListener( MouseEvent.MOUSE_MOVE, onThumbMouseMove );
			stage.addEventListener( MouseEvent.MOUSE_UP, onThumbMouseUp );
			
			if ( e.target == thumb.toLeftButton )
			{	
				offset = thumb.globalToLocal( new Point( e.stageX, e.stageY ) );
				//thumb.toRightButton.visible = false;
				currentAction = RESIZE_LEFT;
				
				
			}
			else if ( e.target == thumb.toRightButton )
			{
				offset = thumb.globalToLocal( new Point( e.stageX, e.stageY ) );
				offset.x -= thumb.contentWidth;
				//thumb.toLeftButton.visible = false;
				currentAction = RESIZE_RIGHT;
			}
			else
			{	
				offset = new Point( e.localX, e.localY );
				//thumb.toRightButton.visible = false;
				//thumb.toLeftButton.visible = false;
				setCursor( Assets.HAND_SQUEEZED_CURSOR );
				currentAction = MOVE;
			}
			
			thumb.mouseDown = true;
			
			//Отсылаем это событие для того что-бы отключить автоматическую прокрутку во время перетаскивания при воспроизведении
			_client.dispatchEvent( new PropertyChangeEvent( PropertyChangeEvent.PROPERTY_CHANGE, false, false, null, 'autoScroll', true, false ) );
		}
		
		private function onThumbMouseMove( e : MouseEvent ) : void
		{
			var pos : Point = globalToLocal( new Point( e.stageX - offset.x, e.stageY - offset.y ) );
			
			if ( pos.x < 0.0 )
			{
				pos.x = 0.0;
			}
			else
				if ( pos.x > width )
				{	
					pos.x = width;
				}
			
			if ( pos.y < 0.0 )
			{
				pos.y = 0;
			}
			else
				if ( pos.y > height )
				{
					pos.y = height;
				}
			
			if ( currentAction == RESIZE_LEFT )
			{
				resizeLeftThumb( pos );
			}
			else if ( currentAction == RESIZE_RIGHT )
			{
				resizeRightThumb( pos );
			}
			else if ( currentAction == MOVE )
			{	
				moveThumb( pos );
			}
		}
		
		private function resizeLeftThumb( pos : Point ) : void
		{
			var s                   : IScale = IScale( _client );
			var globalX             : Number = convertLocalX( pos.x );
			var offset              : Number = _client.horizontalScrollPosition - globalX; 
		    var newSamplesPerWindow : Number = samplesPerWindow + offset * s.scale;
			var newScale            : Number = ( newSamplesPerWindow / samplesPerWindow ) * s.scale;
			
			if ( newScale > TimeLineParameters.MIN_SCALE )
			{
				_client.horizontalScrollPosition = globalX; 
				s.scale = newScale;
				
				UIComponent( _client ).validateNow(); 
				
				invalidateDisplayList();
				validateDisplayList();	
			}
		}
		
		private function resizeRightThumb( pos : Point ) : void
		{
		   var s               : IScale = IScale( _client );
		   var offset          : Number = pos.x - ( thumb.x + thumb.contentWidth );
		   var offsetInSamples : Number = samplesPerWindow + ( ( offset * s.duration ) / width );
		   var newScale        : Number = ( offsetInSamples / samplesPerWindow ) * s.scale; 
		   
		   if ( newScale > TimeLineParameters.MIN_SCALE )
		   {
			   s.scale = newScale;
			   
			   UIComponent( _client ).validateNow(); 
			   invalidateDisplayList();
			   validateDisplayList();  
		   }   
		}	
		
		private function moveThumb( pos : Point ) : void
		{
			if ( ( pos.x + thumb.contentWidth ) > width )
			{
				pos.x = width - thumb.contentWidth;
			}
			
			if ( ( pos.y + thumb.contentHeight ) > height )
			{
				pos.y = height - thumb.contentHeight;
			}	
			
			_client.horizontalScrollPosition = convertLocalX( pos.x );
			_client.verticalScrollPosition = convertLocalY( pos.y );
			
			invalidateDisplayList();
		}	
		
		private function onThumbMouseUp( e : MouseEvent ) : void
		{	
            if ( thumb.hitTestPoint( e.stageX, e.stageY ) )
			{
				if ( ( ! thumb.toLeftButton.hitTestPoint( e.stageX, e.stageY ) ) &&
				   ( ! thumb.toRightButton.hitTestPoint( e.stageX, e.stageY ) ) )
				{
					setCursor( Assets.HAND_CURSOR );
				}
			}
			else
			{
				clearCursor();
			}
			
			currentAction = NONE;
			stage.removeEventListener( MouseEvent.MOUSE_MOVE, onThumbMouseMove );
			stage.removeEventListener( MouseEvent.MOUSE_UP, onThumbMouseUp );
			
			thumb.mouseDown = false;
			
			//Отсылаем это событие для того что-бы включить автоматическую прокрутку во время перетаскивания при воспроизведении
			_client.dispatchEvent( new PropertyChangeEvent( PropertyChangeEvent.PROPERTY_CHANGE, false, false, null, 'autoScroll', false, true ) );
		}
		
		private function convertLocalX( x : Number ) : Number
		{
			return ( x * _client.contentWidth ) / width;
		}
		
		private function convertLocalY( y : Number ) : Number
		{
			return ( y * _client.contentHeight ) / height;
		}	
		
		private function convertGlobalX( x : Number ) : Number
		{
			var s : IScale          = IScale( _client );
			
			return ( width * x * s.scale ) / s.duration;
		}
		
		private function convertGlobalY( y : Number ) : Number
		{	
			return ( height * y ) / _client.contentHeight;
		}
		
		override protected function commitProperties():void
		{
			super.commitProperties();
			
			var v : Boolean = _seq.numChannels > 0;
			visible = includeInLayout = v;
		}
		
		override protected function updateDisplayList( w : Number, h : Number ) : void
		{
			super.updateDisplayList( w, h );
			
			if ( _client )
			{
				
					thumb.visible = true;
					
					thumb.x = convertGlobalX( _client.horizontalScrollPosition ); 
					thumb.y = convertGlobalY( _client.verticalScrollPosition );
					
					if ( _client.contentWidth > _client.width )
					{
						var cW : Number = convertGlobalX( _client.width );
						thumb.contentWidth  = ( thumb.x + cW ) < w ? cW : w - thumb.x;
					}	
					else
					{
						thumb.contentWidth = w;
					}	
					
					if ( _client.contentHeight > _client.height )
					{
						thumb.contentHeight = convertGlobalY( _client.height );
					}	
					else
					{
						thumb.contentHeight = h;
					}	
					
					thumb.invalidateAndTouchDisplayList();
				
			}
			else
			{
				thumb.visible = false;
			}
		}	
	}
}