package components.sequencer.controls
{
	import components.sequencer.ColorPalette;
	import components.sequencer.controls.events.HeaderContainerEvent;
	
	import flash.display.BitmapData;
	import flash.display.LineScaleMode;
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.events.MouseEvent;
	import flash.geom.Rectangle;
	
	import mx.core.BitmapAsset;
	import mx.core.DragSource;
	import mx.core.UIComponent;
	import mx.events.DragEvent;
	import mx.managers.DragManager;
	
	public class ControlContainer extends UIComponent
	{
		private var _bg : Shape;
		
		private static const DRAGGING_OFFSET : Number = 8.0;
		private var _eventInitiator : MouseEvent;
		
		/**
		 * Имя дорожки 
		 */		
		private var _trackName : String;
		private var _trackNameChanged : Boolean;
		
		/**
		 * Номер дорожки 
		 */		
		protected var _number    : int;
		private var _numberChanged : Boolean;
		
		/**
		 * Цвет контейнера 
		 */		
		private var _color : uint = 0x00FF00;
		private var _colorChanged : Boolean = true;
		
		/**
		 * Закладка 
		 */		
		protected var _page : ControlPage;
		
		/**
		 * Заголовок трека 
		 */		
		protected var _header : TrackNumber;
		
		/**
		 * Выделение 
		 */		
		private var _highlight : Shape;
		
		/**
		 * Определяет наведен ли курсор 
		 */		
		private var _hovered : Boolean;
		
		/**
		 * Определяет выбрано\невыбрано 
		 */		
		private var _selected : Boolean;
		
		/**
		 * Дорожка отключена и не звучит 
		 */		
		private var _disabled : Boolean;
		
		public function ControlContainer()
		{
			super();
			
			addEventListener( DragEvent.DRAG_COMPLETE, onDragComplete );
		}
		
		public function get hovered() : Boolean
		{
			return _hovered;
		}
		
		public function set hovered( value : Boolean ) : void
		{
			_hovered = value;
			invalidateDisplayList();
		}
		
		public function get selected() : Boolean
		{
			return _selected;
		}
		
		public function set selected( value : Boolean ) : void
		{
			_selected = value;
			invalidateDisplayList();
		}
		
		public function get disabled() : Boolean
		{
			return _disabled;
		}
		
		public function set disabled( value : Boolean ) : void
		{
			_disabled = value;
			_colorChanged = true;
			invalidateDisplayList();
		}	
		
		private function getSnapShot() : BitmapAsset
		{
			var bitmap : BitmapData = new BitmapData( stage.width, height );
			bitmap.draw( this, null, null, null, new Rectangle( 0, 0, stage.width, height ) );
			
			return new BitmapAsset( bitmap );	
		}	
		
		private function onMouseDown( e : MouseEvent ) : void
		{
			/*if ( ! _header.inEditMode )
			{	*/
			if ( owner.numChildren > 1 ) //Если всего один трек, то нет смысла перетаскивать
			{
				_eventInitiator = e;
				stage.addEventListener( MouseEvent.MOUSE_MOVE, onMouseMove );
				stage.addEventListener( MouseEvent.MOUSE_UP, onMouseUp );
			}	
			/*}*/
		}
		
		private function onMouseUp( e : MouseEvent ) : void
		{
			if ( owner.numChildren > 1 ) //Если всего один трек, то нет смысла перетаскивать
			{
				stage.removeEventListener( MouseEvent.MOUSE_MOVE, onMouseMove );
				stage.removeEventListener( MouseEvent.MOUSE_UP, onMouseUp );	
			}
		}	
		
		private function onMouseMove( e : MouseEvent ) : void
		{
			if ( ( Math.abs( _eventInitiator.stageX - e.stageX ) > DRAGGING_OFFSET ) ||
				( Math.abs( _eventInitiator.stageY - e.stageY ) > DRAGGING_OFFSET )
			)
			{
				onMouseUp( null );
				var dragSource : DragSource = new DragSource();   
				    dragSource.addData( this, 'trackControl' );    
				
				
				DragManager.doDrag( this, dragSource, _eventInitiator, getSnapShot() );
				alpha = 0.05;
			}
		}
		
		private function onDragComplete( e : DragEvent ) : void
		{
			alpha = 1.0;
		}
		
		override protected function createChildren():void
		{
			super.createChildren();
			
			_bg = new Shape();
			_bg.graphics.lineStyle( 1.0, 0xD6D6D6, 0.5, false, LineScaleMode.NONE );
			_bg.graphics.beginFill( 0x232323 );
			_bg.graphics.drawRect( 0, 0, 60, 60 );
			_bg.graphics.endFill();
			
			_header = new TrackNumber();
			_header.addEventListener( MouseEvent.MOUSE_DOWN, onMouseDown );
			
			_page = new ControlPage();
			_page.color = _color;
			_page.text = _trackName;
			_page.addEventListener( MouseEvent.MOUSE_DOWN, onMouseDown );
			
			if ( currentState == 'maximized' )
			{
				_page.currentState = 'minimized';
			}
			else
			{
				_page.currentState = 'maximized';
			}
			
			_highlight = new Shape();
			
			addChild( _bg );
			addChild( _page );
			addChild( _highlight );
			addChild( _header );	
		}
		/*
		private function onStartNameChanging( e : HeaderContainerEvent ) : void
		{
			dispatchEvent( e );	
		}*/	
		/*
		private function onStartNameChanged( e : HeaderContainerEvent ) : void
		{
			//trackName = _header.text;
			dispatchEvent( e );
		}	
		*/
		public function addDigits( v : int ) : String
		{
			if ( v > 9 ) return  v.toString();
			 else return '0' + v.toString();
		}	
		
		override protected function measure() : void
		{
			measuredWidth = 90 + _page.getExplicitOrMeasuredWidth();
			measuredHeight = Settings.TRACK_HEIGHT;
		}	
		
		override protected function commitProperties():void
		{
			super.commitProperties();
			
			if ( _trackNameChanged )
			{
				//_header.text = _trackName;
				_page.text = _trackName;
				_trackNameChanged = false;
			}
			
			if ( _numberChanged )
			{
				_header.label = addDigits( _number + 1 );
				_numberChanged = false;
			}	
		}
		
		override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void
		{
			super.updateDisplayList( unscaledWidth, unscaledHeight );
			
			unscaledWidth -= _page.getExplicitOrMeasuredWidth();
			
			_bg.width = unscaledWidth;
			_bg.height = unscaledHeight + 1;
			
			_header.move( 0, 1 );
			_header.setActualSize( _header.getExplicitOrMeasuredWidth(), _header.getExplicitOrMeasuredHeight() );
			
			if ( _colorChanged )
			{
                _highlight.graphics.clear();
				_highlight.graphics.beginFill( _disabled ? ColorPalette.DISABLED_COLOR : _color, 1 );
				_highlight.graphics.drawRect( 0, 0, 10, 10 );
				_highlight.graphics.endFill();
				
				_page.color = _color;
				
				_colorChanged = false;
			}	
			
			_page.setActualSize( _page.getExplicitOrMeasuredWidth(), unscaledHeight );
			_page.move( unscaledWidth, 0 );
			
			if ( _hovered && _selected )
			{
				_highlight.alpha = 0.6;
			}
			else
			{
				if ( _hovered ) _highlight.alpha = 0.4;
				else  _highlight.alpha = 0.5;	
			}
			
			_highlight.width = unscaledWidth;
			_highlight.height = unscaledHeight;
			_highlight.visible = _hovered || _selected || _disabled;
		}
		
		public function get color() : uint
		{
			return _color;
		}
		
		public function set color( value : uint ) : void
		{
			_color = value;
			_colorChanged = true;
			
			invalidateDisplayList();
		}	
		
		public function get trackName() : String
		{
			return _trackName;
		}
		
		public function set trackName( value : String ) : void
		{
			_trackName = value;
			_trackNameChanged = true;
			invalidateProperties();
		}
		
		public function get number() : int
		{
			return _number;
		}
		
		public function set number( value : int ) : void
		{
			_number = value;
			_numberChanged = true;
			invalidateProperties();
		}	
	}
}