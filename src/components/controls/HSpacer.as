package components.controls
{
	import mx.core.UIComponent;
	
	public class HSpacer extends UIComponent
	{
		private static const PADDING : Number = 0.0;
		
		public function HSpacer()
		{
			super();
		}
		
		override protected function measure():void
		{
			measuredHeight = 1.0;
		}
		
		override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void
		{
			super.updateDisplayList( unscaledWidth, unscaledHeight );
			
			graphics.clear();
			graphics.lineStyle( 2.0, 0x666666, 0.5 );
			graphics.moveTo( PADDING, 0.0 );
			graphics.lineTo( unscaledWidth - PADDING, 0.0 );
		}
	}
}