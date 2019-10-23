package components.hslider
{
	import flash.display.GraphicsPathCommand;
	import flash.filters.DropShadowFilter;
	import flash.filters.GlowFilter;
	
	import mx.skins.ProgrammaticSkin;
	
	public class HSliderTrackSkin extends ProgrammaticSkin
	{
		public function HSliderTrackSkin()
		{
			super();
			
			filters = [ new DropShadowFilter( 5, 45, 0, 1, 5, 5, 0.5, 1, true ),
			            new GlowFilter( 0xCCCCCC, 1.0, 2, 2, 0.66 )    
			];
		}
		
		override public function get measuredHeight() : Number
		{
			return 4.3;
		}
		
		override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void
		{
			super.updateDisplayList( unscaledWidth, unscaledHeight );
			
			graphics.clear();
			graphics.beginFill( 0x505050 );
			graphics.drawRect( 0, 0, unscaledWidth, measuredHeight );
			graphics.endFill();
		}	
	}
}