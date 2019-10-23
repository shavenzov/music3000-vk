package components.controls.users
{
	import components.controls.users.events.AutoScrollableEvent;
	
	import flash.events.MouseEvent;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.utils.clearInterval;
	import flash.utils.setInterval;
	
	import mx.containers.BoxDirection;
	import mx.core.ScrollPolicy;
	import mx.managers.ToolTipManager;
	
	import spark.components.List;
	
	[Event(name="onMoveLeft", type="com.events.AutoScrollableEvent")]
	[Event(name="onMoveRight", type="com.events.AutoScrollableEvent")]
	[Event(name="onStopped", type="com.events.AutoScrollableEvent")]
	public class ScrollableList extends List
	{
		//Максимальная скорость прокурутки Белта
		public var maxSpeed : Number = 10;
		//Размер зоны молчания в обе из сторон
		public var silenceArea : Number = 10;
		
		//Идентификатор таймера
		private var timer_id : uint = 0;
		
		//вкл/выкл автопрокрутку
		private var _autoscroll : Boolean = true;
		//Определяет наведен ли сейчас курсор
		private var _rollOver   : Boolean = false;
		//Определяет направление автопрокрутки
		private var _direction : String = BoxDirection.HORIZONTAL;
		
		//Предыдущее сгенерированное событие
		private var lastEvent : String = AutoScrollableEvent.STOPPED;
		
		public function ScrollableList()
		{
			super();
		}
		
		override protected function createChildren() : void
		{
			super.createChildren();
			
			scroller.setStyle( 'verticalScrollPolicy', ScrollPolicy.OFF );
			scroller.setStyle( 'horizontalScrollPolicy', ScrollPolicy.OFF );
			
			addEventListener( MouseEvent.ROLL_OUT, onRollOut );
			addEventListener( MouseEvent.MOUSE_MOVE, onMouseMove );
		}
		
		public function get direction() : String
		{
			return _direction;
		}
		
		public function set direction( value : String ) : void
		{
			_direction = value;
		}
		
		private function onRollOut( e : MouseEvent ) : void
		{
			clearTimer();
			_rollOver = false;
		}
		
		private function onMouseMove( e : MouseEvent ) : void
		{
			 setTimer();
			_rollOver = true;
		}   
		
		public function get autoscroll() : Boolean
		{
			return _autoscroll;
		}
		
		public function set autoscroll( value : Boolean ) : void
		{
			if ( _autoscroll != value )
			{
				
				_autoscroll = value;	
				
				if ( _autoscroll )
				{
					if ( _rollOver ) setTimer();
				}
				else clearTimer();
			}	
		}
		
		private function scroll() : void
		{
			var local : Number;
			var center : Number;
			var viewPos : Number;
			var maxViewPos : Number;
			
			if ( _direction == BoxDirection.HORIZONTAL )
			{
				local = mouseX;
				center = width / 2;
				viewPos = dataGroup.horizontalScrollPosition;
				maxViewPos = dataGroup.contentWidth - width;
			}
			else
			{
				local = mouseY;
				center = height / 2;
				viewPos = dataGroup.verticalScrollPosition;
				maxViewPos = dataGroup.contentHeight - height;
			}
			
		
			//Определяем направление вращения скролла
			var dir : Number = 0.0;
			
			//Проверяем не попадаем ли мы в зону молчания
			if ( ( local <= center + silenceArea ) && ( local >= center - silenceArea ) )
			{
				sendEvent( AutoScrollableEvent.STOPPED );
			}  
			else
			{
				var speed : Number = ( maxSpeed * Math.abs( center - local ) ) / center;
				
				if ( local > center )
				{
					if ( viewPos >= maxViewPos )
					{
						sendEvent( AutoScrollableEvent.STOPPED );
					}	
					else
					{
						sendEvent( AutoScrollableEvent.MOVE_RIGHT );
						dir = speed;
					}
				}
				else 
				{
					if ( viewPos <= 0 )
					{
						sendEvent( AutoScrollableEvent.STOPPED );
					}	
					else
					{
						sendEvent( AutoScrollableEvent.MOVE_LEFT );
						dir = - speed;
					}
				}
			}
			
			dir = Math.round( dir );
			
			if ( Math.abs( dir ) > 0.0 )
			{
				if ( _direction == BoxDirection.HORIZONTAL )
				{
					dataGroup.horizontalScrollPosition += dir;
				}
				else
				{
					dataGroup.verticalScrollPosition += dir;
				}
				
				ToolTipManager.updatePos();
			}
		}
		
		//Генерирует определенное событие
		private function sendEvent( type : String ) : void
		{
			if ( type != lastEvent )
			{
				//Если белт остановился указываем в каком направлении он двигался до этого
				if ( type == AutoScrollableEvent.STOPPED ) dispatchEvent( new AutoScrollableEvent( type, lastEvent ) );
				else 
				{
					//Если произошла мгновенная смена собятий с LEFT на RIGHT в промежутке обязательно генерируем STOPPED
					if ( lastEvent != AutoScrollableEvent.STOPPED )
					{
						dispatchEvent( new AutoScrollableEvent( AutoScrollableEvent.STOPPED, lastEvent ) );
					}
					dispatchEvent( new AutoScrollableEvent( type ) );
				}
				
				lastEvent = type;
			}
		}
		
		private function setTimer() : void
		{
			if ( ( timer_id == 0 ) && ( _autoscroll ) ) timer_id = setInterval( this.scroll, 10 );
		}
		
		private function clearTimer() : void
		{
			if ( timer_id != 0 )
			{
				clearInterval( timer_id );
				timer_id = 0;
				sendEvent( AutoScrollableEvent.STOPPED );
			}
		}
			
		public function scrollToIndex( index : int ) : void
		{
			var spDelta:Point = dataGroup.layout.getScrollPositionDeltaToElement(index);
			
			if (spDelta)
			{
				var itemBounds : Rectangle = layout.getElementBounds(index);
				var newPos:Number;
				
				if ( _direction == BoxDirection.HORIZONTAL )
				{
					newPos = spDelta.x + dataGroup.width;
					
					if ( newPos < dataGroup.contentWidth - dataGroup.width )
					{
						dataGroup.horizontalScrollPosition += newPos - itemBounds.width;
					}
					else
					{
						dataGroup.horizontalScrollPosition = dataGroup.contentWidth;
					}
				}
				else
				{
					newPos = spDelta.y + dataGroup.height;
					
					if ( newPos < dataGroup.contentHeight - dataGroup.height )
					{
						dataGroup.verticalScrollPosition += newPos - itemBounds.height;
					}
					else
					{
						dataGroup.verticalScrollPosition = dataGroup.contentHeight;
					}
				}
			}
		}
	}
}