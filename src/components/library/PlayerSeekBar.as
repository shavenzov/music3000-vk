package components.library
{
	import flash.display.Sprite;
	import flash.events.MouseEvent;
	import flash.filters.GlowFilter;
	
	import mx.core.UIComponent;
	
	public class PlayerSeekBar extends UIComponent
	{
		private var thumb : Sprite;
		
		/**
		 * Текущее значение загрузки 0..1 
		 */		
		private var _progress : Number = 0.5;
		
		/**
		 * Максимальное значение 
		 */		
		private var _maxValue : Number = 100;
		
		/**
		 * Текущее значение 
		 */		
		private var _value : Number = 0;
		
		public function PlayerSeekBar()
		{
			super();
			//blendMode = BlendMode.INVERT;
		}
		
		public function get progress() : Number
		{
			return _progress;
		}
		
		public function set progress( value : Number ) : void
		{
			_progress = value;
			invalidateDisplayList();
		}
		
		public function get visibility() : Boolean
		{
			return alpha > 0.0;
		}
		
		public function set visibility( value : Boolean ) : void
		{
			if ( value )
			{
				alpha = 1.0;
			}
			else
			{
				alpha = 0.0;
			}
		}
		
		public function get maxValue() : Number
		{
			return _maxValue;
		}
		
		public function set maxValue( value : Number ) : void
		{
			_maxValue = value;
			invalidateDisplayList();
		}
		
		public function get value() : Number
		{
			return _value;
		}
		
		public function set value( v : Number ) : void
		{
			_value = v;
			invalidateDisplayList();
		}
		
		public function get xValue() : Number
		{
			return ( _value * unscaledWidth ) / _maxValue
		}
		
		public function set xValue( posX : Number ) : void
		{
			if ( posX < 0.0 )
			{
				return;
			}
			
			var newValue : Number = ( _maxValue * posX ) / unscaledWidth;
			
			if ( newValue > _maxValue )
			{
				return;
			}
			
			value = newValue;
		}
		
		private function onThumbRollOver( e : MouseEvent ) : void
		{
			thumb.filters = [ new GlowFilter( 0xffffff, 0.5 ) ];
		}
		
		private function onThumbRollOut( e : MouseEvent ) : void
		{
			thumb.filters = null;
		}
		
		override protected function measure():void
		{
			measuredWidth  = 250;
			measuredHeight = 0;
		}
		
		override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void
		{
			var c : Number = unscaledHeight - 1;
			
			graphics.clear();
			
			if ( parent )
			{
				graphics.lineStyle();
				graphics.beginFill( 0xa5640a, 0.0 );
				graphics.drawRect( -2, - parent.height, unscaledWidth + 2, parent.height );
				graphics.endFill();
			}
			
			if ( _progress > 0 )
			{	
				graphics.lineStyle( 1.0, 0xffffff, 1.0 );
				graphics.moveTo( 0, c );
				graphics.lineTo( unscaledWidth * _progress, c );
			}
			
			thumb.x = ( ( _value * unscaledWidth ) / _maxValue ) - thumb.width / 2;
			thumb.y = -5;
		}
		
		override protected function createChildren():void
		{
			thumb = new Sprite();
			thumb.graphics.beginFill( 0xffffff );
			thumb.graphics.drawRect( 0.0, 0.0, 10.0, 5.0 );
			thumb.graphics.endFill();
			//thumb.buttonMode = true;
			//thumb.addEventListener( MouseEvent.ROLL_OVER, onThumbRollOver );
			//thumb.addEventListener( MouseEvent.ROLL_OUT, onThumbRollOut );
			
			addChild( thumb );
		}
	}
}