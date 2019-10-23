package components.hslider
{
	import flash.display.GraphicsPathCommand;
	import flash.display.Shape;
	import flash.filters.BevelFilter;
	import flash.filters.DropShadowFilter;
	import flash.filters.GlowFilter;
	
	import mx.skins.RectangularBorder;
	
	public class HSliderThumbSkin extends RectangularBorder
	{	
		
		public function HSliderThumbSkin()
		{
			super();
			
		}
		
		override public function get measuredWidth():Number
		{
			return 15.25;
		}
		
		override public function get measuredHeight() : Number
		{
			return 7.95;
		}	
		
		override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void
		{
			super.updateDisplayList( unscaledWidth, unscaledHeight );
			
		    graphics.clear();
			graphics.beginFill( 0x666666 );
			graphics.drawRoundRectComplex( 0, 0, unscaledWidth, unscaledHeight, 4.5, 4.5, 4.5, 4.5 ); 
			graphics.endFill();
			
			graphics.lineStyle( 0.8, 0xFFD200, 0.75 );
			graphics.drawCircle( unscaledWidth / 2, unscaledHeight / 2, 1.4 );
			
			filters = [ 
				new BevelFilter( 2, ( name == 'thumbDownSkin' ) ? 75 : 45, 0xFFFFFF, 1.0, 0x000000, 1.0, 4.0, 4.0, 0.32 ),
				new GlowFilter( 0xCCCCCC, 1.0, 2.0, 2.0 )/*,
				
				new DropShadowFilter( 4.0, 9, 0, 1.0, 4.0, 4.0, 0.45 )*/
				
			          ];
		}	
	}
}