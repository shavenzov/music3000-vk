package components.controls
{
	import flash.events.MouseEvent;
	
	import flashx.textLayout.formats.TextDecoration;
	
	import spark.components.RichText;
	
	public class TextLink extends RichText
	{
		private var _hovered : Boolean;
		
		public function TextLink()
		{
			super();
			addEventListener( MouseEvent.ROLL_OVER, onRollOver );
			addEventListener( MouseEvent.ROLL_OUT, onRollOut );
		}
		
		private function onRollOver( e : MouseEvent ) : void
		{
			_hovered = true;
			invalidateDisplayList();
		}
		
		private function onRollOut( e : MouseEvent ) : void
		{
			_hovered = false;
			invalidateDisplayList();
		}
		
		override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void
		{
			super.updateDisplayList( unscaledWidth, unscaledHeight );
			
			graphics.clear();
			
			if ( _hovered )
			{
				graphics.lineStyle( 1, 0xffffff );
				graphics.moveTo( -1, unscaledHeight );
				graphics.lineTo( unscaledWidth + 1, unscaledHeight );
			}
		}
	}
}