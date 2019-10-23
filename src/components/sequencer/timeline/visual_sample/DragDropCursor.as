package components.sequencer.timeline.visual_sample
{
	import flash.display.BlendMode;

	public class DragDropCursor extends BaseVisualSample
	{
		public function DragDropCursor()
		{
			super();
			blendMode = BlendMode.SCREEN;
		}
		
		private function draw() : void
		{
			graphics.clear();
			
			graphics.beginFill( _color, 0.5 );
			graphics.drawRect( 3.7, 2, contentWidth - 3.7, contentHeight - 4 );
			graphics.endFill();
			
			graphics.lineStyle( 3.7, _color );
			graphics.drawRect( 0, 0, 0, contentHeight );
			graphics.drawRect( contentWidth, 0, 0, contentHeight );
		}	
		
		override protected function update():void
		{
			draw();
		}	
	}
}