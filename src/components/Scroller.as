/**
 * Расширяет функционал Scroller добавляя поддержку 4-x дополнительных св-в см. ниже
 * + вертикальную прокрутку колесиком 
 */
package components
{
	import components.supportClasses.ScrollerLayout;
	
	import flash.events.MouseEvent;
	
	import spark.components.Group;
	import spark.components.Scroller;
	
	public class Scroller extends spark.components.Scroller
	{
		public var vScrollBarTop    : Number = 0;
        public var vScrollBarBottom : Number = 0;
		
		public var hScrollBarLeft   : Number = 0;
		public var hScrollBarRight  : Number = 0;
		
		public function Scroller()
		{
			super();
			focusEnabled = true;
			addEventListener( MouseEvent.MOUSE_WHEEL, onMouseWheel );
		}
		
		private function onMouseWheel( e : MouseEvent ) : void
		{
			verticalScrollBar.value -= e.delta * 2;
		}	
		
		override protected function attachSkin():void
		{
			super.attachSkin();
			Group( skin ).layout = new ScrollerLayout();
		}
	}
}