/**
 * Корешок панели управления треком.
 * Имеет два состояния свернуто\развернуто  minimized/maximized
 */
package components.sequencer.controls
{
	import flash.display.BlendMode;
	import flash.display.DisplayObject;
	import flash.filters.GlowFilter;
	
	import mx.core.IUITextField;
	import mx.core.UIComponent;
	import mx.core.UIFTETextField;
	import mx.core.mx_internal;
	import mx.effects.Tween;
	import mx.effects.easing.Cubic;
	import mx.states.State;
	
	
	public class ControlPage extends UIComponent
	{
		/**
		 * Цвет корешка 
		 */		
		private var _color : uint;
		private var _colorChanged : Boolean = true;
		
		/**
		 * Названия трека в развернутом состоянии 
		 */		
		private var _textLabel : IUITextField;
		private var _text : String;
		
		//анимационный tween
		private var _tween : Tween;
		//Время раскрытия скрытия
		private var _time  : int = 250;
		
		public function ControlPage()
		{
			super();
			states = [ new State( { name : 'minimized' } ) , new State( { name : 'maximized' } ) ];
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
		
		public function get text() : String
		{
			return _text;
		}
		
		public function set text( value : String ) : void
		{
			_text = value;
			invalidateProperties();
		}	
		
		override protected function createChildren():void
		{
			super.createChildren();
			
			setStyle( 'toolTipPlacement', 'errorTipRight' );
			
			_textLabel = IUITextField( createInFontContext( UIFTETextField ) );
			_textLabel.rotation = -90;
			_textLabel.filters = [ new GlowFilter( 0x333333, 0.85, 4.0, 4.0, 2 ) ];
			
			addChild( DisplayObject( _textLabel ) );
			
			if ( currentState == 'maximized' )
			{
				setMaximizeState();
			}
			else setMinimizeState();
		}	
		
		public function getMaximizedWidth() : Number
		{
			return 18;
		}
		
		public function getMinimizedWidth() : Number
		{
		   return 8;	
		}
		
		private function setMinimizeState() : void
		{
		  _textLabel.visible = false;
		  toolTip = 'Щелкни для выхода из режима "настройка дорожки"'; 
		}
		
		private function setMaximizeState() : void
		{
			_textLabel.visible = true;
			toolTip = 'Щелкни для перехода в режим "настройка дорожки"'; 
		}	
		
		override protected function measure():void
		{
			super.measure();
			
			if ( currentState == 'maximized' )
			{
				measuredWidth = getMaximizedWidth();
			}
			else
			{
				measuredWidth = getMinimizedWidth();
			}	
		}
		
		override protected function commitProperties():void
		{
			super.commitProperties();
			
			if ( _textLabel.text != _text )
			{
				_textLabel.text = _text;
				invalidateDisplayList();
			}	
		}	
		
		private function drawBG( w : Number, h : Number ) : void
		{
			graphics.clear();
			graphics.beginFill( _color );
			graphics.drawRect( 0, 0, w, h );
			graphics.endFill();
		}	
		
		override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void
		{
			super.updateDisplayList( unscaledWidth, unscaledHeight );
			
			drawBG( unscaledWidth, unscaledHeight );
			
			if ( currentState == 'maximized' )
			{
				_textLabel.setActualSize( unscaledHeight - 4, _textLabel.getExplicitOrMeasuredHeight() );
				_textLabel.move( ( ( unscaledWidth - _textLabel.getExplicitOrMeasuredHeight() ) / 2 ) - 1, 
					             _textLabel.getExplicitOrMeasuredWidth() < unscaledHeight ? unscaledHeight - ( unscaledHeight - _textLabel.getExplicitOrMeasuredWidth() ) / 2 : unscaledHeight - 2 );
			}	
		}	
		
		override protected function stateChanged(oldState:String, newState:String, recursive:Boolean):void
		{
			super.stateChanged( oldState, newState, recursive );
			
			if ( initialized )
			{
				if ( newState == 'maximized' )
				{
					setTween( getExplicitOrMeasuredWidth(), getMaximizedWidth(), _time, Cubic.easeOut );
				}
				else
				{
					setMinimizeState();
					setTween( getExplicitOrMeasuredWidth(), getMinimizedWidth(), _time );
				}	
			}	
		}
		
		private function setTween( startValue : Number, endValue : Number, duration : Number, easingFunction : Function = null ) : void
		{
			_tween = new Tween( this, startValue, endValue, duration );
			if ( easingFunction != null )
				_tween.easingFunction = easingFunction;
		}
		
		mx_internal function onTweenUpdate(value:Number):void
		{
			explicitWidth = value;
		}
		
		mx_internal function onTweenEnd( value:Number ) : void
		{
			if ( currentState == 'maximized' ) setMaximizeState();
			explicitWidth = NaN;
			_tween = null;
			invalidateSize();
		}
	}
}