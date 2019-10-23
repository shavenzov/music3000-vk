package components.controls
{
	import mx.controls.Button;
	import flash.display.DisplayObject;
	import flash.text.TextLineMetrics;
	import mx.core.UITextField;
	import flash.text.TextFieldAutoSize;
	
	import mx.core.IFlexDisplayObject;
	import mx.core.mx_internal;
	
	use namespace mx_internal;
	
	public class MultilineButton extends Button
	{
		public function MultilineButton()
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