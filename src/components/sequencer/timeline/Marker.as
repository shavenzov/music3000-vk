package components.sequencer.timeline
{
	import com.audioengine.core.AudioData;
	import com.audioengine.core.TimeConversion;
	
	import components.Base;
	import components.sequencer.timeline.events.MarkerEvent;
	
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.geom.Point;

	public class Marker extends Base implements IScale, IPosition
	{
		/**
		 * Прилипания в контрольных точках при прохождении бегунка
		 */		
		protected var _stickToGrid : Boolean = true;
		
		/**
		 * Полная привязка к сетке 
		 */		
		protected var _snapToGrid  : Boolean = false;
		
		/**
		 * Привязка к сетке при изменении св-ва xPosition 
		 */		
		protected var _snapToGridThenXChange : Boolean = true;
		
		/**
		 * Область прилипания относительно сетки 
		 */		
		private const _stickingArea : Number = 0.01 * AudioData.RATE;
		
		private var _sliping      : Boolean;
		private const _slipingCount : Number = 6.0;
		private var _slipingInc   : Number = 0;
		
		/**
		 * Текущий интервал залипания 
		 */		
		public var stickInterval : Number;
		
		/**
		 * Масштаб отображения 
		 */		
		protected var _scale : Number;
		
		/**
		 * Длительность в фреймах
		 */		
		protected var _duration : Number;
		
		/**
		 * Положение курсора в секундах 
		 */		
		protected var _position : Number = 0;
		
		/**
		 * Значение левой границы 
		 */		
		protected var _leftBorder : Number = 0.0;
		
		/**
		 * Размеры курсора 
		 */		
		protected var _cursorWidth  : Number;
		protected var _cursorHeight : Number;
		
		/**
		 *Курсор в настоящийй момент перетаскивается 
		 * 
		 */
		private var _dragging : Boolean;
		private var _draggingOffset : Number;
		
		/**
		 * Смещение курсора, в зависимомти от формы 
		 */		
		protected var _offset : Number = 0;
		
		/**
		 * Смещение начала временной шкалы 
		 */		
		public var leftPadding : Number;
		
		/**
		 * Предыдущие размеры 
		 */		
		private var _lastContentHeight : Number = 0.0;
		private var _lastContentWidth  : Number = 0.0;
		
		public function Marker()
		{
			super();
			cacheAsBitmap = true;
			addEventListener( MouseEvent.MOUSE_DOWN, onMouseDown );
		}
		
		private function nextSlipping() : void
		{
			_slipingInc ++;
			if ( _slipingInc > _slipingCount )
			{
				_sliping = false;
				_slipingInc = 0;
			}
		}
		
		public function get stickToGrid() : Boolean
		{
			return _stickToGrid;
		}
		
		public function set stickToGrid( value : Boolean ) : void
		{
			_stickToGrid = value;
			_sliping = false;
			_slipingInc = 0;
		}	
		
		/**
		 * Проверяет нужно ли прилипнуть к этой точке или нет 
		 * @param time - время точки в секундах
		 * @return - прилипнуть / неприлипнуть
		 * 
		 */		
		private function sticking( time : Number, stickPoint : Number ) : Boolean
		{
			_sliping =  Math.abs( time - stickPoint ) <= _stickingArea;
			
			return _sliping;
		}
		
		/**
		 * Возвращает ближайшую временную точку на треке к которой можно "прилипнуть" 
		 * @param time время точки в секундах
		 * @return скоректированное значение
		 * 
		 */		
		private function getNearestStickPoint( time : Number ) : Number
		{
			return Math.round( time / stickInterval ) * stickInterval;
		}
		
		public function get offset() : Number
		{
			return _offset;
		}
		
		public function set offset( value : Number ) : void
		{
			_offset = value;
		}	
		
		/**
		 * Положение курсора воспроизведения в фреймах
		 */		
		public function get position() : Number
		{
			return _position;
		}	
		/**
		 * Устанавливает положение маркера в фреймах. Не устанавливается во время перетаскивания маркера пользователем 
		 * @param value
		 * 
		 */		
		public function set position( value : Number ) : void
		{
			if ( ( value != _position ) && ! _dragging )
			{
				_position = value;
				updatePosition();
			}	
		}
		
		/**
		 * Устанавливает новое положение маркера, даже если курсор перетаскивается пользователем 
		 * @param value
		 * 
		 */		
		public function setPosition( value : Number ) : void
		{
			if ( value != _position )
			{
				_position = value;
				updatePosition();
			}
		}
		
		/**
		 * Устанавливает новое положение маркера, даже если курсор перетаскивается пользователем
		 * Производится проверка на выход за пределы и жесткая привязка к сетке, если эта опция включена 
		 * @param pos
		 * 
		 */		
		public function setAndValidatePosition( pos : Number ) : void
		{
			if ( pos != _position )
			{
				pos = correctPosition( pos );
				
				//Полностью привязываем к сетке
				if ( _snapToGridThenXChange )
				{
					pos = getNearestStickPoint( pos );
				}
				
				_position = pos;
				updatePosition();
			}	
		}	
		
		public function get timePosition() : Number
		{
			return TimeConversion.numSamplesToSeconds( _position ); 
		}
		
		public function set timePosition( value : Number ) : void
		{
			position = TimeConversion.secondsToNumSamples( value );
		}	
		
		/**
		 * Положение курсора воспроизведения в координатах по оси x
		 */		
		public function get xPosition() : Number
		{
			return x + leftPadding - _offset;
		}
		
		public function set xPosition( value : Number ) : void
		{
			_position = correctPosition( calculatePosition( value - leftPadding  ) );
			
			//Полностью привязываем к сетке
			if ( _snapToGridThenXChange )
			{
				_position = getNearestStickPoint( _position );
			}	
			
			updatePosition();
			dispatchEvent( new Event( Event.CHANGE ) );
		}
		
		/**
		 * Преобразует значение координаты x в количество семплов
		 * @param _x - положение по оси x
		 * @return значение координаты преобразованное в секунды
		 * 
		 */		
		protected function calculatePosition( _x : Number ) : Number
		{
			return _x  * _scale;
		}
		
		protected function correctPosition( pos : Number ) : Number
		{
			if ( pos < _leftBorder ) pos = _leftBorder;
			if ( pos > _duration ) pos = _duration;
			
			return pos;
		}	
		
		private function onMouseDown( e : MouseEvent ) : void
		{
			_draggingOffset = e.localX;
			
			stage.addEventListener( MouseEvent.MOUSE_MOVE, onMouseMove );
			stage.addEventListener( MouseEvent.MOUSE_UP, onMouseUp );
			
			_dragging = true;
			
			dispatchEvent( new Event( MarkerEvent.MARKER_PRESS ) );
		}
		
		private function onMouseMove( e : MouseEvent ) : void
		{
			if ( ! _sliping )
			{
				var localX : Number = parent.globalToLocal( new Point( e.stageX - leftPadding -  _draggingOffset + _offset, e.stageY ) ).x;
				var newPos : Number = correctPosition( calculatePosition( localX ) ); 
				
				if ( _snapToGrid ) //Привязка к сетке
				{
					newPos = getNearestStickPoint( newPos );
				}	
				else
				if (  _stickToGrid ) //Прилипание к сетке
				{
					var stickPos : Number = getNearestStickPoint( newPos );
					
					if ( sticking( newPos, stickPos ) )
					{
						newPos = stickPos;
						_sliping = true;
					}
				}		
				
				if ( newPos != _position )
				{
					_position = newPos;
					
					var event : Event = new Event( Event.CHANGE, false, true );
					dispatchEvent( event );
					//Если это событие отменено, то не обновляем положение
					if ( ! event.isDefaultPrevented() )
					{
						updatePosition();	
					}	
				}	
			}
			else
			{
				nextSlipping();  	  
			}
		}
		
		private function onMouseUp( e : MouseEvent ) : void
		{
			if ( _dragging ) //Для предотвращения нескольких событий при выходе мыши за границы браузера
			{
				_dragging = false;
				
				stage.removeEventListener( MouseEvent.MOUSE_MOVE, onMouseMove );
				stage.removeEventListener( MouseEvent.MOUSE_UP, onMouseUp );
				
				dispatchEvent( new Event( MarkerEvent.MARKER_RELEASE ) );
			}	
		}	
		
		public function get dragging() : Boolean
		{
			return _dragging;
		}
		
		public function get scale() : Number
		{
			return _scale;
		}
		
		public function set scale( value : Number ) : void
		{
		  _scale = value;
		  _needMeasure = true;
		  _needUpdate = true;
		}
		
		public function get leftBorder() : Number
		{
			return _leftBorder;
		}
		
		public function set leftBorder( value : Number ) : void
		{
			if ( value != _leftBorder )
			{
				_leftBorder = value;
				position = correctPosition( _position );
			}
		}
		
		public function get duration() : Number
		{
			return _duration;
		}
		
		public function set duration( value : Number ) : void
		{
			_duration = value;
			_needMeasure = true;
			_needUpdate = true;
		}
		
		/**
		 * Ф-ия отрисовки курсора 
		 * 
		 */		
		protected function draw() : void
		{	
			
		}
		
		protected function updatePosition() : void
		{
			x = ( _position / _scale ) + leftPadding - _offset;
		}	
		
		override protected function update():void
		{
			if ( ( _lastContentHeight != contentHeight ) || ( _lastContentWidth != contentWidth ) )
			{
				draw();
				_lastContentHeight = contentHeight;
				_lastContentWidth  = contentWidth;
			}
			
			updatePosition();
		}	
	}
}