package components.controls
{
	import mx.controls.LinkButton;
	
	public class LinkButton extends mx.controls.LinkButton
	{
		public function LinkButton()
		{
			super();
			focusEnabled = false;
			tabEnabled = false;
			useHandCursor = false;
		}
		
		override public function set enabled( value : Boolean ) : void
		{
			super.enabled = value;
			alpha = value ? 1 : 0.1;
		}
		
		override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void
		{
			super.updateDisplayList( unscaledWidth, unscaledHeight );
			
			graphics.beginFill( 0x000000, 0.0 );
			graphics.drawRect( 0.0, 0.0, unscaledWidth, unscaledHeight );
			graphics.endFill();
		}
	}
}