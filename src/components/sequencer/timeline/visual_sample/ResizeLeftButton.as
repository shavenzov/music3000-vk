package components.sequencer.timeline.visual_sample
{
	import components.Base;
	
	import flash.display.CapsStyle;
	import flash.display.GraphicsPathCommand;
	import flash.display.JointStyle;
	import flash.display.LineScaleMode;
	import flash.events.MouseEvent;

	public class ResizeLeftButton extends Base
	{
		public function ResizeLeftButton()
		{
			super();
			alpha = 0.75;
			
			addEventListener( MouseEvent.MOUSE_OVER, onMouseOver );
			addEventListener( MouseEvent.MOUSE_OUT, onMouseOut );
		}
		
		private function onMouseOver( e : MouseEvent ) : void
		{
		 alpha = 1; 	
		}
		
		private function onMouseOut( e : MouseEvent ) : void
		{
			alpha = 0.75;
		}	
		
		override protected function update():void
		{
			graphics.clear();
			
		   graphics.beginFill( 0x00ff00, 0.0 );
		   graphics.drawRect( - 5, -5, contentWidth + 5, contentHeight + 5 );
		   graphics.endFill();
		   
		   graphics.lineStyle( 2, 0xffffff, 1, false, LineScaleMode.NORMAL, CapsStyle.NONE, JointStyle.MITER, 60 );
		   graphics.drawPath( Vector.<int>( [ GraphicsPathCommand.MOVE_TO, 
			   GraphicsPathCommand.LINE_TO,
			   GraphicsPathCommand.MOVE_TO, 
			   GraphicsPathCommand.LINE_TO,
			   GraphicsPathCommand.MOVE_TO, 
			   GraphicsPathCommand.LINE_TO,
			   GraphicsPathCommand.LINE_TO ] ),
			   Vector.<Number>( [ 8.1, 24.25,
				   8.1, 17.45,
				   0.0, 0.0,
				   0.0, 41.75,
				   8.1, 17.45,
				   1.15, 20.9,
				   8.1, 24.25 ] )
			   
		   );
		}
		
		override protected function measure():void
		{
			contentWidth  = 8.1;
			contentHeight = 41.75;
		}	
	}
}