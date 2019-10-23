package components.controls
{
	import mx.core.UIComponent;
	
	public class UIIndicator extends UIComponent
	{
		private var indicator : Indicator;
		
		public function UIIndicator()
		{
			super();
		}
		
		override protected function createChildren():void
		{
			if ( ! indicator )
			{
				indicator = new Indicator();
				addChild( indicator );
			}
		}
		
		override protected function measure() : void
		{
			measuredWidth = 24;
			measuredHeight = 24;
		}
		
		override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void
		{
			indicator.width = unscaledWidth;
			indicator.height = unscaledHeight;
			
			indicator.x = unscaledWidth / 2;
			indicator.y = unscaledHeight / 2;
		}
	}
}