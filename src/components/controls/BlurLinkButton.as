package components.controls
{
	import flash.filters.BlurFilter;
	
	import mx.controls.LinkButton;
	
	public class BlurLinkButton extends LinkButton
	{
		private var blur : BlurFilter;
		
		public function BlurLinkButton()
		{
			super();
			
			blur = new BlurFilter( 2, 2 );
		}
		
		override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void
		{
			super.updateDisplayList( unscaledWidth, unscaledHeight );
			
			if ( enabled )
			{
				blur.blurX = blur.blurY = 2;
			}
			else
			{
				blur.blurX = blur.blurY = 4;
			}
			
			filters = [ blur ];
		}
	}
}