package components.sequencer.timeline
{
	import components.ScrollableBase;
	import components.sequencer.timeline.events.MarkerChangeEvent;
	import components.sequencer.timeline.events.MarkerEvent;
	import components.sequencer.timeline.events.TracingEvent;
	
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.geom.Rectangle;
	import flash.utils.clearInterval;
	import flash.utils.clearTimeout;
	import flash.utils.setInterval;
	import flash.utils.setTimeout;
	
	import mx.managers.DoubleClickManager;

	public class Markers extends ScrollableBase implements IScale, IPosition
	{
		/**
		 * Масштаб отображения 
		 */		
		private var _scale : Number;
		
		/**
		 * Длительность в секундах
		 */		
		private var _duration : Number;
		
		/**
		 * Головка воспроизведения 
		 */		
		public var _playHead : PlayHead;
		
		/**
		 * Левая граница петли 
		 */		
		public var _leftLoopBorder : LeftLoopBorder;
		
		public var _loopMarker : LoopMarker;
		
		/**
		 * Правая граница петли 
		 */		
		public var _rightLoopBorder : RightLoopBorder;
		
		/**
		 * Головка установки длины микса 
		 */		
		public var _durationHead : DurationHead;
		
		/**
		 * Отступ сверху для головки воспроизведения
		 */		
		private const _playHeadPaddingTop : Number = 0.0;
		
		/**
		 * Отступ сверху головки установки длины микса 
		 */		
		private const _durationHeadPaddingTop : Number = 0.0;
		
		/**
		 * Отступ сверху для границ петли 
		 */		
		private const _loopBorderPaddingTop : Number = 0.0;
		
		/**
		 * Смещение шкалы времени, для того что-бы правильно обрезать маркеры в положении 0 
		 */		
		private var _offset : Number;
		
		/**
		 * Запоминаем здесь значение stickToGrid для playHead 
		 */		
		private var _playHeadStickToGrid : Boolean;
		
		public function Markers()
		{
			super();
			
			_loopMarker = new LoopMarker();
			_loopMarker.addEventListener( MarkerEvent.MARKER_PRESS, onLoopMarkerPress );
			_loopMarker.addEventListener( MarkerEvent.MARKER_RELEASE, onLoopMarkerRelease );
			_loopMarker.addEventListener( Event.CHANGE, onLoopPositionChanged );
			
			_leftLoopBorder = new LeftLoopBorder();
			_leftLoopBorder.addEventListener( MarkerEvent.MARKER_PRESS, onLoopMarkerPress );
			_leftLoopBorder.addEventListener( MarkerEvent.MARKER_RELEASE, onLoopMarkerRelease );
			_leftLoopBorder.addEventListener( Event.CHANGE, onLeftLoopBorderPositionChanged );
			
			_rightLoopBorder = new RightLoopBorder();
			_rightLoopBorder.addEventListener( MarkerEvent.MARKER_PRESS, onLoopMarkerPress );
			_rightLoopBorder.addEventListener( MarkerEvent.MARKER_RELEASE, onLoopMarkerRelease );
			_rightLoopBorder.addEventListener( Event.CHANGE, onRightLoopBorderPositionChanged );
			
			_playHead = new PlayHead();
			_playHead.addEventListener( MarkerEvent.MARKER_PRESS, onPlayHeadPress );
			_playHead.addEventListener( MarkerEvent.MARKER_RELEASE, onPlayHeadRelease );
			_playHead.addEventListener( Event.CHANGE, onPlayHeadPositionChanged );
			
			_durationHead = new DurationHead();
			_durationHead.leftBorder = TimeLineParameters.MIN_DURATION;
			_durationHead.addEventListener( MarkerEvent.MARKER_PRESS, onDurationHeadPress );
			_durationHead.addEventListener( MarkerEvent.MARKER_RELEASE, onDurationHeadRelease );
			_durationHead.addEventListener( Event.CHANGE, onDurationHeadPositionChanged );
			
			addChild( _playHead );
			
			_offset = Math.max( _playHead.offset, _leftLoopBorder.offset, _rightLoopBorder.offset, _loopMarker.offset );
			leftPadding = _offset;
		}
		
		public function get leftPadding() : Number
		{
			return _playHead.leftPadding;
		}
		
		public function set leftPadding( value : Number ) : void
		{
			_playHead.leftPadding        = value;
			_durationHead.leftPadding    = value;
			_rightLoopBorder.leftPadding = value;
			_leftLoopBorder.leftPadding  = value;
			_loopMarker.leftPadding      = value;
		}	
		
		private function onStartMoving( e : TracingEvent ) : void
		{
		  if ( _playHead.stickToGrid )
		  {
			  _playHead.stickToGrid = false;
			  _playHeadStickToGrid = true;
		  }	  
		}
		
		private function onStopMoving( e : TracingEvent ) : void
		{
			if ( _playHeadStickToGrid )
			{
				_playHeadStickToGrid = true;
			}	
		}	
		
		private function onPlayHeadPositionChanged( e : Event ) : void
		{
			dispatchEvent( new MarkerChangeEvent( MarkerChangeEvent.PLAYHEAD_POSITION_CHANGED, _playHead.position ) );
		}
		
		private function onDurationHeadPositionChanged( e : Event ) : void
		{
			dispatchEvent( new MarkerChangeEvent( MarkerChangeEvent.DURATION_POSITION_CHANGED, _durationHead.position ) ); 
		}
		
		private function onLoopPositionChanged( e : Event ) : void
		{
			_leftLoopBorder.position = _loopMarker.position;
			_rightLoopBorder.position = _loopMarker.end;
			
			dispatchEvent( new MarkerChangeEvent( MarkerChangeEvent.LEFT_LOOP_BORDER_POSITION_CHANGED, _leftLoopBorder.position ) );
			dispatchEvent( new MarkerChangeEvent( MarkerChangeEvent.RIGHT_LOOP_BORDER_POSITION_CHANGED, _rightLoopBorder.position ) );
		}	
		
		private function onLeftLoopBorderPositionChanged( e : Event ) : void
		{
			//Нельзя залезать за пределы правой границы
			if ( ( _rightLoopBorder.position - _leftLoopBorder.position ) < stickInterval )
			{
				e.preventDefault();
				_leftLoopBorder.setPosition( _rightLoopBorder.position - stickInterval );
			}
			
			dispatchEvent( new MarkerChangeEvent( MarkerChangeEvent.LEFT_LOOP_BORDER_POSITION_CHANGED, _leftLoopBorder.position ) );
		    
			_loopMarker.position = _leftLoopBorder.position;
			updateLoopDuration()
			_loopMarker.invalidateAndTouchDisplayList();
		}
		
		private function onRightLoopBorderPositionChanged( e : Event ) : void
		{
			//Нельзя залезать за пределы левой границы
			if ( ( _rightLoopBorder.position - _leftLoopBorder.position ) < stickInterval )
			{
				e.preventDefault();
				_rightLoopBorder.setPosition( _leftLoopBorder.position + stickInterval );
			}
			
			dispatchEvent( new MarkerChangeEvent( MarkerChangeEvent.RIGHT_LOOP_BORDER_POSITION_CHANGED, _rightLoopBorder.position ) );
		    
			updateLoopDuration();
			_loopMarker.invalidateAndTouchDisplayList();
		}
		
		private function onLoopMarkerPress( e : Event ) : void
		{
			if ( e.currentTarget == _loopMarker )
			{
					DoubleClickManager.mouseDown( this, new Event( MarkerEvent.LOOP_MARKER_PRESS ) );	
			}	
			else if ( e.currentTarget == _leftLoopBorder )
			{	
				DoubleClickManager.mouseDown( this, new Event( MarkerEvent.LEFT_LOOP_BORDER_PRESS ) );
			}
			else 
			{
				DoubleClickManager.mouseDown( this, new Event( MarkerEvent.RIGHT_LOOP_BORDER_PRESS ) );
			}	
				
			dispatchEvent( new TracingEvent( TracingEvent.START_TRACING, true, false ) ); 	
		}
		
		private function onLoopMarkerRelease( e : Event ) : void
		{
			if ( DoubleClickManager.double_click )
			{
				loopMarkers = false;
				dispatchEvent( new MarkerChangeEvent( MarkerChangeEvent.LOOP_CHANGED_OFF, -1.0 ) );
			}
			
			if ( e.currentTarget == _loopMarker )
			{
				DoubleClickManager.mouseUp( new Event( MarkerEvent.LOOP_MARKER_RELEASE ) );	
			}	
			else if ( e.currentTarget == _leftLoopBorder )
			{	
				DoubleClickManager.mouseUp( new Event( MarkerEvent.LEFT_LOOP_BORDER_RELEASE ) );
			}
			else 
			{
				DoubleClickManager.mouseUp( new Event( MarkerEvent.RIGHT_LOOP_BORDER_RELEASE ) );
			}
			
			dispatchEvent( new TracingEvent( TracingEvent.STOP_TRACING ) );
		}
		
		private function onDurationHeadPress( e : Event ) : void
		{
			dispatchEvent( new Event( MarkerEvent.DURATION_PRESS ) );
			dispatchEvent( new TracingEvent( TracingEvent.START_TRACING, true, false ) );
		}
		
		private function onDurationHeadRelease( e : Event ) : void
		{
			dispatchEvent( new Event( MarkerEvent.DURATION_RELEASE ) );
			dispatchEvent( new TracingEvent( TracingEvent.STOP_TRACING ) );
		}
		
		private function onPlayHeadPress( e : Event ) : void
		{
			dispatchEvent( new Event( MarkerEvent.PLAYHEAD_PRESS ) );
			
			addEventListener( TracingEvent.START_MOVING, onStartMoving );
			addEventListener( TracingEvent.STOP_MOVING, onStopMoving );
			
			dispatchEvent( new TracingEvent( TracingEvent.START_TRACING, true, false, null, true ) ); 
		}
		
		private function onPlayHeadRelease( e : Event ) : void
		{
			dispatchEvent( new Event( MarkerEvent.PLAYHEAD_RELEASE ) );
			dispatchEvent( new TracingEvent( TracingEvent.STOP_TRACING ) );
			
			removeEventListener( TracingEvent.START_MOVING, onStartMoving );
			removeEventListener( TracingEvent.STOP_MOVING, onStopMoving );
		}	
		
		/**
		 * Вкл/Выкл маркер установки длины микса 
		 * @return 
		 * 
		 */		
		public function get durationMarker() : Boolean
		{
			return _durationHead.parent != null;
		}
		
		public function set durationMarker( value : Boolean ) : void
		{
			if ( value != durationMarker )
			{
				if ( value )
				{
					addChildAt( _durationHead, 0 );
				}
				else
				{
					removeChild( _durationHead );
				}
				
				_needUpdate = true;
			}
		}
		
		/**
		 * Вкл\выкл маркеры отображающие границы "петли" 
		 * @return 
		 * 
		 */		
		public function get loopMarkers() : Boolean
		{
			return _leftLoopBorder.parent != null;
		}
		
		public function set loopMarkers( value : Boolean ) : void
		{
			if ( value != loopMarkers )
			{
				if ( value )
				{
					addChildAt( _leftLoopBorder, 0 );
					addChildAt( _rightLoopBorder, 0 );
					addChildAt( _loopMarker, 0 );
					
					//dispatchEvent( new MarkerChangeEvent( MarkerChangeEvent.LOOP_CHANGED_ON, -1.0 ) );
				}
				else
				{
					removeChild( _loopMarker );
					removeChild( _leftLoopBorder );
					removeChild( _rightLoopBorder );
					
					//dispatchEvent( new MarkerChangeEvent( MarkerChangeEvent.LOOP_CHANGED_OFF, -1.0 ) );
				}
				
				_needUpdate = true;
			}
		}
		
		/**
		 * Устанавливает область зацикливания 
		 * @param start положение 1 в фреймах
		 * @param end положение 2 в фреймах
		 * 
		 */		
		public function setLoopRegion( start : Number, end : Number ) : void
		{
			if ( end > start )
			{
				_leftLoopBorder.position  = start;
				_rightLoopBorder.position = end;
				
				updateLoopDuration();
			}
			
			if ( end < start )
			{
				_leftLoopBorder.position  = end;
				_rightLoopBorder.position = start;
				
				updateLoopDuration();
			}	
		}
		
		public function setXLoopRegion( startX : Number, endX : Number ) : void
		{
			if ( endX > startX )
			{
				_leftLoopBorder.xPosition  = startX;
				_rightLoopBorder.xPosition = endX;
				
				updateLoopDuration();
			}
			
			if ( endX < startX )
			{
				_leftLoopBorder.xPosition  = endX;
				_rightLoopBorder.xPosition = startX;
				
				updateLoopDuration();
			} 
		}
		
		/**
		 * Определяет находится ли курсор воспроизведения внутри "петли" 
		 * @return 
		 * 
		 */		
		public function isCursorInLoop() : Boolean
		{
		   if ( _playHead.position > _rightLoopBorder.position )
		   {  
			   return false;
		   }
		   
		   if ( _playHead.position < _leftLoopBorder.position )
		   {
			   return false;
		   }   
			
		   return true;
		}	
		
		public function get scale() : Number
		{
			return _scale;
		}
		
		public function set scale( value : Number ) : void
		{
			_scale = value;
			_playHead.scale = value;
			_durationHead.scale = value;
			_leftLoopBorder.scale = value;
			_rightLoopBorder.scale = value;
			_loopMarker.scale = value;
			
			_needMeasure = true;
			_needUpdate = true;
		}
		
		public function get duration() : Number
		{
			return _duration;
		}
		
		public function set duration( value : Number ) : void
		{
			_duration = value;
			_playHead.duration = value;
			_durationHead.duration = value;
			_leftLoopBorder.duration = value;
			_rightLoopBorder.duration = value;
			_loopMarker.duration = value;
			
			//Головку длины микса всегда устанавливаем в конец
			if ( ! _durationHead.dragging )
			{
				_durationHead.position = value;
			}
			
			_needMeasure = true;
			_needUpdate = true;
		}
		
		public function get xPosition() : Number
		{
			return _playHead.xPosition;
		}
		
		public function set xPosition( value : Number ) : void
		{
			_playHead.xPosition = value;
		}	
		
		public function get position() : Number
		{
			return _playHead.position;
		}
		
		public function set position( value : Number ) : void
		{
			_playHead.position = value;
		}
		
		public function get leftLoopXPosition() : Number
		{
			return _leftLoopBorder.xPosition;
		}
		
		public function set leftLoopXPosition( value : Number ) : void
		{	
			_leftLoopBorder.xPosition = value;
			_loopMarker.xPosition     = value;
			updateLoopDuration();
		}
		
		public function get leftLoopPosition() : Number
		{
		  return _leftLoopBorder.position;
		}
		
		public function set leftLoopPosition( value : Number ) : void
		{
			_leftLoopBorder.position = value;
			_loopMarker.position = value;
			updateLoopDuration();
		}	
		
		public function get rightLoopXPosition() : Number
		{
			return _rightLoopBorder.xPosition;
		}
		
		public function set rightLoopXPosition( value : Number ) : void
		{
			_rightLoopBorder.xPosition = value;
			updateLoopDuration();
		}	
		
		public function get rightLoopPosition() : Number
		{
			return _rightLoopBorder.position;
		}
		
		public function set rightLoopPosition( value : Number ) : void
		{
			_rightLoopBorder.position = value;
			updateLoopDuration();
		}	
		
		public function get timePosition() : Number
		{
			return _playHead.timePosition;
		}
		
		public function set timePosition( value : Number ) : void
		{
			_playHead.timePosition = value;
		}	
		
		override protected function measure():void
		{
			contentWidth = _duration / _scale;
			contentWidth += offset;
		}
		
		override public function updateScrollRect():void
		{
			if ( _scrollRectChanged )
			{
				scrollRect = new Rectangle( _hsp, 0.0, _scrollWidth, _scrollHeight );
				_scrollRectChanged = false;
			}
		}	
		
		override protected function update():void
		{
			var len : Number = _vsp + _scrollHeight;
			var sH  : Number = ( len > contentHeight ) ?  _scrollHeight - ( len - contentHeight ) : _scrollHeight; 
			
			_playHead.y = _playHeadPaddingTop;
			//_playHead.contentWidth = contentWidth - _offset;
			_playHead.contentHeight = sH - _playHeadPaddingTop;
			
			_durationHead.y = _durationHeadPaddingTop;
			_durationHead.contentHeight = sH - _durationHeadPaddingTop;
			
			_leftLoopBorder.y = _loopBorderPaddingTop;
			//_leftLoopBorder.contentWidth = _playHead.contentWidth;
			_leftLoopBorder.contentHeight = sH - _loopBorderPaddingTop;
			
			_rightLoopBorder.y = _loopBorderPaddingTop;
			//_rightLoopBorder.contentWidth = _playHead.contentWidth;
			_rightLoopBorder.contentHeight = sH - _loopBorderPaddingTop;
			
			_loopMarker.y = _loopBorderPaddingTop;
			updateLoopDuration();
		}
		
		private function updateLoopDuration() : void
		{
			_loopMarker.loopDuration = _rightLoopBorder.position - _leftLoopBorder.position;
			_loopMarker.position = _leftLoopBorder.position;
			_loopMarker.touch();
		}	
		
		override public function touch():void
		{
			super.touch();
			_playHead.touch();
			_durationHead.touch();
			_leftLoopBorder.touch();
			_rightLoopBorder.touch();
			_loopMarker.touch();
		}
		
		override public function invalidateAndTouch():void
		{
			super.invalidateAndTouch();
			_playHead.invalidateAndTouch();
			_durationHead.invalidateAndTouch();
			_leftLoopBorder.invalidateAndTouch();
			_rightLoopBorder.invalidateAndTouch();
			_loopMarker.invalidateAndTouch();
		}	
		
		public function get offset() : Number
		{
			return _offset;
		}
		
		public function get stickInterval() : Number
		{
			return _playHead.stickInterval;
		}
		
		public function set stickInterval( value : Number ) : void
		{
			_playHead.stickInterval = value;
			_durationHead.stickInterval = value;
			_rightLoopBorder.stickInterval = value;
			_leftLoopBorder.stickInterval = value;
			_loopMarker.stickInterval = value;
		}	
	}
}