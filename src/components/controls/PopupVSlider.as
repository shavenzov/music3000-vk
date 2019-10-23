package components.controls
{
	import flash.geom.Rectangle;
	
	import mx.controls.VSlider;
	import mx.core.mx_internal;
	import mx.effects.Tween;
	import mx.events.FlexEvent;
	
	use namespace mx_internal;
	
	public class PopupVSlider extends VSlider
	{	
		private var tween : Tween;
		
		private static const TWEEN_DURATION : Number = 250;
		
		public function PopupVSlider()
		{
			super();
			alpha = 0;
		}
		
		public static const _left   : Number = 5;
		public static const _right  : Number = 10;
		public static const _top    : Number = 5;
		public static const _bottom : Number = 10;
		
		override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void
		{
			super.updateDisplayList( unscaledWidth, unscaledHeight ); 
			
			graphics.clear();
			graphics.beginFill( 0x333333 );
			graphics.drawRect( - _left, - _top, width + _right, height + _bottom );
			graphics.endFill();
		}
		
		private function clearTween() : void
		{
			if ( tween )
			{
				tween.stop();
				tween = null;
			}
		}
		
		public function show() : void
		{
			clearTween();
			tween = new Tween( this, 0.0, 1.0, TWEEN_DURATION );
		}
		
		public function hide() : void
		{
			clearTween();
			tween = new Tween( this, 1.0, 0.0, TWEEN_DURATION );
		}
		
		public function get animation() : Boolean
		{
			return tween != null;
		}
		
		mx_internal function onTweenUpdate(value:Number):void
		{
			alpha = value;
		}
		
		mx_internal function onTweenEnd( value:Number ) : void
		{
			if ( alpha < 0.2 )
			{
				dispatchEvent( new FlexEvent( FlexEvent.HIDE ) );
			}
			else
			{
				dispatchEvent( new FlexEvent( FlexEvent.SHOW ) );
			}
			tween = null;
		}
	}
}