/**
* ...
* @author Shavenzov Denis
* @version 0.1
* @e-mail Snowbird666@gmail.com
* 
* Расширяет стандартный компонент ToolTip, включает поддержку HTML форматирования
*/
package components.controls
{
	import mx.controls.ToolTip;

	public class HTMLToolTip extends ToolTip
	{
		public function HTMLToolTip()
		{
			super();
		}
		
		override protected function commitProperties():void
		{
			super.commitProperties();             
			textField.htmlText = text; 
		}
		
	}
}