/**
 * Реализация контрола "Круговой регулятор" 
 */
package components.circularknob
{
	import com.utils.NumberUtils;
	
	import flash.display.DisplayObject;
	import flash.display.Graphics;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.ui.Keyboard;
	import flash.utils.clearInterval;
	import flash.utils.setInterval;
	
	import mx.controls.ToolTip;
	import mx.core.UIComponent;
	import mx.events.SliderEvent;
	import mx.managers.IFocusManagerComponent;
	
	/**
	 * Использовать ли маленькие засечки 
	 */	
	[Style(name="notch", type="Boolean", inherit="no")]
	/**
	 * Толщина засечек 
	 */	
	[Style(name="notchThicknes", type="Number", inherit="no")]
	/**
	 * Цвет засечек 
	 */	
	[Style(name="notchColor", type="uint", inherit="no")]
	/**
	 * Длина засечек 
	 */	
	[Style(name="notchLength", type="Number", inherit="no")]
	/**
	 * Шаг нанесения засечек в градусах 
	 */	
	[Style(name="notchStep", type="uint", inherit="no")]
	
	/**
	 * Использовать ли вторые засечки 
	 */	
	[Style(name="notch2", type="Boolean", inherit="no")]
	/**
	 * Толщина засечек 2 
	 */	
	[Style(name="notchThicknes2", type="Number", inherit="no")]
	/**
	 * Цвет засечек 2
	 */	
	[Style(name="notchColor2", type="uint", inherit="no")]
	/**
	 * Длина засечек 2
	 */	
	[Style(name="notchLength2", type="Number", inherit="no")]
	/**
	 * Шаг нанесения засечек в градусах 2 
	 */	
	[Style(name="notchStep2", type="uint", inherit="no")]
	
	/**
	 * Скин заднего фона 
	 */	
	[Style(name="bgSkin", type="Class", inherit="no")]
	
	/**
	 * Скин регулятора 
	 */	
	[Style(name="knobSkin", type="Class", inherit="no")]
	
	[Event(name="change", type="mx.events.SliderEvent")]
	[Event(name="thumbPress", type="mx.events.SliderEvent")]
	[Event(name="thumbRelease", type="mx.events.SliderEvent")]
	public class CircularKnob extends UIComponent implements IFocusManagerComponent
	{
		/**
		 * Задний фон 
		 */		
		public var _bg   : CircularKnobBackground;
		
		/**
		 * Регулятор
		 */
		public var _knob : CircularKnobSkin;
		
		/**
		 * Контейнер в котором находится регулятор 
		 */
		public var _knobContainer : Sprite;
		
		/**
		 * Экземпляр всплывающей подсказки 
		 */		
		private var _toolTip : ToolTip;
		
		/**
		 * Предыдущее значение X, при перетаскивании 
		 */		
		private var _lastX : Number;
		
		/**
		 * Предыдущее значение Y, при перетаскивании 
		 */	
		private var _lastY : Number;
		
		/**
		 * Минимальное значение
		 */		
		private var _minValue : Number = 0.0;
		private var _minValueChanged : Boolean;
		
		/**
		 * Максимальное значение
		 */		
		private var _maxValue : Number = 100.0;
		private var _maxValueChanged : Boolean;
		/**
		 * Диапазон значений 
		 */		
		private var _valueRange : Number;
		
		/**
		 * Минимальный угол поворота
		 */		
		private var _minRotation : Number = 0.0;
		private var _minRotationChanged : Boolean;
		
		/**
		 * Максимальный угол поворота
		 */		
		private var _maxRotation : Number = 360.0;
		private var _maxRotationChanged : Boolean;
		
		/**
		 * Диапазон поворота регулятора 
		 */		
		private var _rotationRange : Number;
		
		/**
		 * Текущий угол поворота 
		 */		
		private var _rotation : Number = 0.0;
		private var _rotationChanged : Boolean;
		
		/**
		 * Текущее значение 
		 */		
		private var _value : Number = 0.0;
		private var _valueChanged : Boolean;
		
		/**
		 * отображать ли всплывающую подсказку
		 */		
		private var _showDataTip : Boolean = true;
		private var _showDataTipChanged : Boolean;
		
		/**
		 * Определяет нажата-ли сейчас клавиша мыши 
		 */		
		private var _mouseDown : Boolean;
		
		private var _cW : Number;
		private var _cH : Number;
		
		public function CircularKnob()
		{
			super();
			recalculateRotationRange();
			recalculateValueRange();
			recalculateRotation();	
		}
		
		/**
		 * Значение чувствительности регулятора 
		 */		
		public var sensitive : Number = 1;
		
		/**
		 * Область прлипания к контрольным значениям 
		 */		
		public var stickingArea : Number = 0;
		
		/**
		 * Значения на которых регулятор должен залипать на некоторое время 
		 */		
		public var stickingValues : Vector.<Number>;
		
		/**
		 * Вкл\выкл залипания 
		 */		
		public var sticking : Boolean;
		
		private var _sliping      : Boolean;
		private const _slipingCount : Number = 5;
		private var _slipingInc   : Number = 0;
		
		/**
		 * отображать ли всплывающую подсказку
		 */	
		public function get showDataTip() : Boolean
		{
		   return _showDataTip;	
		}
		
		public function set showDataTip( value : Boolean ) : void
		{
			if ( value != _showDataTip )
			{
				_showDataTip = value;
				_showDataTipChanged = true;
				invalidateProperties();
			}	
		}	
		
		/**
		 * Текущее значение 
		 */
		[Bindable ("valueChanged")]
		public function get value() : Number
		{
			return _value;
		}
		
		public function set value( value : Number ) : void
		{
			if ( ( _value >= _minValue ) && ( _value <= _maxValue ) )
			{
				_value = value;
				_valueChanged = true;
				invalidateProperties();
			}	
		}	
		
		/**
		 * Минимальное значение
		 */	
		public function get minValue() : Number
		{
			return _minValue;
		}
		
		public function set minValue( value : Number ) : void
		{
			if ( value < _maxValue )
			{
				_minValue = value;
				_minValueChanged = true;
				invalidateProperties();	
			}
		}
		
		/**
		 * Максимальное значение
		 */
		public function get maxValue() : Number
		{
			return _maxValue;
		}
		
		public function set maxValue( value : Number ) : void
		{
			if ( value > _minValue )
			{
				_maxValue = value;
				_maxValueChanged = true;
				invalidateProperties();	
			}
		}
		
		/**
		 * Минимальный угол поворота в градусах
		 */
		public function get minRotation() : Number
		{
			return _minRotation;
		}
		
		public function set minRotation( value : Number ) : void
		{
		  if ( value < _maxRotation )
		  {
			  _minRotation = value;
			  _minValueChanged = true;
			  invalidateProperties();  
		  }
		}
		
		/**
		 * Максимальный угол поворота в градусах
		 */	
		public function get maxRotation() : Number
		{
			return _maxRotation;
		}
		
		public function set maxRotation( value : Number ) : void
		{
			if ( value > _minRotation )
			{
				_maxRotation = value;
				_maxRotationChanged = true;
				invalidateProperties();	
			}
		}
		
		override protected function createChildren():void
		{
			super.createChildren();
			
			_knobContainer = new Sprite();
			_knob = new CircularKnobSkin();
			_knob.addEventListener( MouseEvent.MOUSE_DOWN, onMouseDown );
			
			_cW = _knob.width;
			_cH = _knob.height;
			
			_knobContainer.addChild( _knob );
			_bg = new CircularKnobBackground();
			
			addChild( _bg );
			addChild( _knobContainer );
		}	
		
		
		private var key_inc  : Number = 0.01;
		
		private function updateKeyDown( inc : Number ) : void
		{
			if ( ! key_pressed )
			{
				dispatchEvent( new SliderEvent( SliderEvent.THUMB_PRESS, false, false, -1, _value ) );
				key_pressed = true;
			}
			
			var cV : Number = _value + inc;
			
			if ( inc > 0.0 )
			{
				if ( cV > _maxValue )
				{
					value = _maxValue;
					
					return;
				}	
			}
			
			if ( inc < 0.0 )
			{
				if ( cV < _minValue )
				{
					value = _minValue;
					
					return;
				}	
			}	
			
			value = cV;
			
			showToolTip();
			updateToolTip();
			
			dispatchEvent( new SliderEvent( SliderEvent.CHANGE, false, false, -1, _value ) );
		}	
		
		private var key_pressed : Boolean;
		
		override protected function keyDownHandler( e : KeyboardEvent ) : void
		{
		  if ( e.keyCode == Keyboard.LEFT )
		  {
			  updateKeyDown( - key_inc );
			  return;
		  }
		  
		  if ( e.keyCode == Keyboard.RIGHT )
		  {
			  updateKeyDown( key_inc );
			  return; 
		  }
		}
		
		override protected function keyUpHandler( e : KeyboardEvent ) : void
		{
			hideToolTip();
			key_pressed = false;
			dispatchEvent( new SliderEvent( SliderEvent.THUMB_RELEASE, false, false, -1, _value ) );
		}	
		
		private function saveLastPosition( x : Number, y : Number ) : void
		{
			_lastX = x;
			_lastY = y;
		}	
		
		private function onMouseDown( e : MouseEvent ) : void
		{
			saveLastPosition( e.stageX, e.stageY );
			
			stage.addEventListener( MouseEvent.MOUSE_MOVE, onMouseMove );
			stage.addEventListener( MouseEvent.MOUSE_UP, onMouseUp );
			
			_mouseDown = true;
			
			if ( _showDataTip )
			{
				showToolTip();
			}
			
			dispatchEvent( new SliderEvent( SliderEvent.THUMB_PRESS, false, false, -1, _value ) );
		}
		
		private function onMouseUp( e : MouseEvent ) : void
		{
			stage.removeEventListener( MouseEvent.MOUSE_MOVE, onMouseMove );
			stage.removeEventListener( MouseEvent.MOUSE_UP, onMouseUp );
			
			_mouseDown = false;
			
			if ( _showDataTip )
			{
				hideToolTip();
			}
			
			dispatchEvent( new SliderEvent( SliderEvent.THUMB_RELEASE, false, false, -1, _value ) );
		}
		
		private function onMouseMove( e : MouseEvent ) : void
		{
		  	//Регулируем залипание к контрольным точкам
			if ( _sliping )
			{
				_slipingInc ++;
				if ( _slipingInc > _slipingCount )
				{
					_slipingInc = 0;
					_sliping = false;
				}	
			}
			else
			{
				var r : Number = _rotation + ( /*_lastX - e.stageX +*/ _lastY - e.stageY ) * sensitive;
				saveLastPosition( e.stageX, e.stageY );
				
				if ( r <= _minRotation ) 
				{
					_rotation = _minRotation;
				}
				else if ( r >= _maxRotation )
				{
					_rotation = _maxRotation;
				}
				else
				{
					_rotation = r;
				}	
				
				_rotationChanged = true;
				invalidateProperties();	
			}		
		}
		
		private function showToolTip() : void
		{
			if ( ! _toolTip )
			{
				
					_toolTip = new ToolTip();
					_toolTip.text = formatToolTipValue( _value );
					
					_toolTip.owner = this;
					_toolTip.isPopUp = true;
					
					systemManager.toolTipChildren.addChild (DisplayObject( _toolTip ) );
					_toolTip.validateNow();
					_toolTip.setActualSize( _toolTip.getExplicitOrMeasuredWidth(),
						                    _toolTip.getExplicitOrMeasuredHeight() );
					placeToolTip();
					
			}	
		}
		
		private function hideToolTip() : void
		{
			if ( _toolTip )
			{
				systemManager.toolTipChildren.removeChild( DisplayObject( _toolTip ) );
				_toolTip = null;
			}	
		}
		
		protected function placeToolTip() : void
		{
		  var notchLength  : Number  = getStyle( 'notchLength' );
		  var notchLength2 : Number  = getStyle( 'notchLength2' );
			
		  var position : Point = _knobContainer.parent.localToGlobal( new Point( _knobContainer.x, _knobContainer.y ) )
		  var x : Number =  position.x + ( _cW - _toolTip.getExplicitOrMeasuredWidth() ) / 2;
		  var y : Number =  position.y - _cH - 15 - Math.max( notchLength, notchLength2 );
		  
		  if ( x < 0 ) x = 0;
			  
		  _toolTip.move( x, y );	
		}	
		
		private function updateToolTip() : void
		{
			if ( _toolTip )
			{
				_toolTip.text = formatToolTipValue( _value );
				_toolTip.validateNow();
				placeToolTip();	
			}	
		}
		
		protected function formatToolTipValue( v : Number ) : String
		{
			return  NumberUtils.roundTo( v, 2 ).toString();
		}	
		
		override protected function commitProperties():void
		{
			super.commitProperties();
			
			if ( _rotationChanged )
			{
				recalculateValue();
				updateToolTip();
				_rotationChanged = false;
				dispatchEvent( new Event( "valueChanged" ) );
				dispatchEvent( new SliderEvent( SliderEvent.CHANGE, false, false, -1, _value ) );
			}	
			
			if ( _valueChanged )
			{
				recalculateRotation();
				updateToolTip();
				_valueChanged = false;
			}
			
			if ( _minValueChanged || _maxValueChanged )
			{
				recalculateValueRange();
				recalculateRotation();
				_minValueChanged = false;
				_maxValueChanged = false;
			}
			
			if ( _minRotationChanged || _maxRotationChanged )
			{
				recalculateRotationRange();
				recalculateRotation();
				
				_minRotationChanged = false;
				_maxRotationChanged = false;
			}
			
			if ( _showDataTipChanged )
			{
				if ( _mouseDown )
				{
					if ( _showDataTip )
					{
						showToolTip();
					}
					else
					{
					  hideToolTip();	
					}	
				}	
				
				_showDataTipChanged = false;
			}	
			
			invalidateDisplayList();
		}
		
		private function recalculateRotationRange() : void
		{
			_rotationRange = _maxRotation - _minRotation;
		}	
		
		private function recalculateValueRange() : void
		{
		  _valueRange = _maxValue - _minValue;
		}	
		
		private function recalculateRotation() : void
		{
			_rotation = _minRotation + ( ( _value - _minValue ) * _rotationRange ) / _valueRange;
		}
		
		/**
		 * Проверяет прилипаем ли мы к контрольной точке или нет 
		 * @param v - значение для проверки
		 * @return скорректированное значение (контрольная точка) или NaN - если контрольная точка не найдена
		 * 
		 */		
		private function checkSticking( v : Number ) : Number
		{
			if ( sticking && stickingValues )
			{
				var i : int = 0;
				
				while( i < stickingValues.length )
				{
					if ( ( ( stickingValues[ i ] + stickingArea ) > v ) && ( ( stickingValues[ i ] - stickingArea ) < v ) )
					{
						return stickingValues[ i ];
					}	
					
					i ++;
				}	
			}	
			
			return NaN;
		}	
		
		private function recalculateValue() : void
		{
			var newValue       : Number = _minValue + ( ( _rotation - _minRotation ) * _valueRange ) / _rotationRange;
			var correctedValue : Number = checkSticking( newValue );
			
			if ( isNaN( correctedValue ) )
			{
				_value = newValue;
			}
			else
			{
				_value = correctedValue;
				recalculateRotation();
				_sliping = true;
			}
		}	
		
		override protected function measure() : void
		{
			super.measure();
			
			var drawNotch    : Boolean = getStyle( 'notch' );
			var drawNotch2   : Boolean = getStyle( 'notch2' );
			var notchLength  : Number  = getStyle( 'notchLength' );
			var notchLength2 : Number  = getStyle( 'notchLength2' );
			var increment    : Number = 0;
			
			if ( drawNotch && drawNotch2 )
			{
			  	increment = Math.max( notchLength, notchLength2 );
			}
			else if ( drawNotch )
			{
				increment = notchLength;
			}
			else if ( drawNotch2 )
			{
				increment = notchLength2;
			}
			
			measuredMinWidth  = measuredWidth  = _bg.width + 2 * increment + 10;
			measuredMinHeight = measuredHeight = _bg.height + 2 * increment + 10;
		}	
		
		override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void
		{
			super.updateDisplayList( unscaledWidth, unscaledHeight );
			
			_bg.x = ( unscaledWidth - _bg.width  ) / 2;
			_bg.y = ( unscaledHeight - _bg.height  ) / 2;
				
			_knobContainer.x = ( unscaledWidth - _cW ) / 2;
			_knobContainer.y = ( unscaledHeight - _cH ) / 2
			
			rotateKnob();
            
			var g : Graphics = graphics;
			    g.clear();
			var draw : Boolean = getStyle( 'notch' );
			
			if ( draw )
			{
				drawNotch( g, getStyle( 'notchThicknes' ), 
					          getStyle( 'notchColor' ), 
							  getStyle( 'notchLength' ), 
							  getStyle( 'notchStep' )    );
			}
			
			draw = getStyle( 'notch2' );
			
			if ( draw )
			{
				drawNotch( g, getStyle( 'notchThicknes2' ), 
					getStyle( 'notchColor2' ), 
					getStyle( 'notchLength2' ), 
					getStyle( 'notchStep2' )    );
			}
			
			/*
			graphics.lineStyle( 1, 0x00ff00 );
			graphics.drawRect( 0, 0, unscaledWidth, unscaledHeight );
			*/
		}
		
		private function rotateKnob() : void
		{
			var matrix:Matrix = _knob.transform.matrix;
			var w:Number = _cW / 2 - 0.9;
			var h:Number = _cH / 2 - 0.9;
			matrix.identity();
			matrix.translate(-w, -h);
			matrix.rotate( _rotation / 180 * Math.PI );
			matrix.translate( w, h );
			_knob.transform.matrix = matrix;
		}
		
		private function drawNotch( g : Graphics, thickness : Number, color : uint, length : Number, step : Number ) : void
		{
			var r  : Number = ( _bg.width / 2 ) + 3;
			var r2 : Number = r + length;
			var centerX : Number = getExplicitOrMeasuredWidth() / 2;
			var centerY : Number = getExplicitOrMeasuredHeight() / 2;
			
			g.lineStyle( thickness, color );
			
			for ( var i : int = _minRotation; i <= _maxRotation; i += step )
			{
				var rad : Number = i / 180 * Math.PI;
				var x1  : Number = centerX + r * Math.sin( rad );
				var x2  : Number = centerX + r2 * Math.sin( rad );
				
				var y1  : Number = centerY + r * Math.cos( rad );
				var y2  : Number = centerY + r2 * Math.cos( rad );
				
				g.moveTo( x1, y1 );
				g.lineTo( x2, y2 );
			}
		}	
		
		override public function styleChanged(styleProp:String):void
		{
			if ( initialized )
			{
				super.styleChanged( styleProp );	
			}	
		}	
		
		override public function stylesInitialized():void
		{
			super.stylesInitialized();
			
			if ( getStyle( 'notch' )         === undefined ) setStyle( 'notch', true );
			if ( getStyle( 'notchThicknes' ) === undefined ) setStyle( 'notchThicknes', 0.5 );
			if ( getStyle( 'notchColor' )    === undefined ) setStyle( 'notchColor', 0xffffff );
			if ( getStyle( 'notchLength' )   === undefined ) setStyle( 'notchLength', 1 );
			if ( getStyle( 'notchStep' )     === undefined ) setStyle( 'notchStep', 25 );
			if ( getStyle( 'notch2' )        === undefined ) setStyle( 'notch2', true );
			if ( getStyle( 'notchThicknes2' )=== undefined ) setStyle( 'notchThicknes2', 1 );
			if ( getStyle( 'notchColor2' )   === undefined ) setStyle( 'notchColor2', 0xffffff );
			if ( getStyle( 'notchLength2' )  === undefined ) setStyle( 'notchLength2', 3 );
			if ( getStyle( 'notchStep2' )    === undefined ) setStyle( 'notchStep2', 50 );
		}	
    }		
}