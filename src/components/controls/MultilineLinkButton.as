package components.controls
{
	import flash.text.TextFieldAutoSize;

	public class MultilineLinkButton extends LinkButton
	{
		public function MultilineLinkButton()
		{
			super();
		}
		override protected function createChildren():void
		{
			super.createChildren();
			textField.multiline = true;
			textField.wordWrap = true;
			textField.autoSize = TextFieldAutoSize.LEFT;
		}
		
		override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void
		{
			super.updateDisplayList(unscaledWidth, unscaledHeight);
			textField.y = (this.height-textField.height)>>1;
		}
	}
}