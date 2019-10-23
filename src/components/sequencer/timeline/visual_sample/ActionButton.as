package components.sequencer.timeline.visual_sample
{
	import components.Base;
	
	import flash.display.CapsStyle;
	import flash.display.GraphicsPathCommand;
	import flash.display.JointStyle;
	import flash.display.LineScaleMode;
	import flash.events.MouseEvent;
	
	public class ActionButton extends Base
	{
		/**
		 * Семпл к которому прикреплена кнопка 
		 */		
		public var source : BaseVisualSample;
		
		public function ActionButton()
		{
			super();alpha = 0.75;
			
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
			
			
			graphics.beginFill( 0xffffff, 0.0 );
			graphics.drawRect( 0, 0, contentWidth, contentHeight );
			graphics.endFill();
			
			
			graphics.lineStyle( 2, 0xffffff, 1, false, LineScaleMode.NORMAL, CapsStyle.NONE, JointStyle.MITER, 60 );
			
			
			
			graphics.drawCircle( 8.75, 8.75, 8.75 );
			graphics.drawPath( Vector.<int>( [ GraphicsPathCommand.MOVE_TO,
											   GraphicsPathCommand.LINE_TO,
											   GraphicsPathCommand.MOVE_TO,
											   GraphicsPathCommand.LINE_TO,
											   GraphicsPathCommand.MOVE_TO,
											   GraphicsPathCommand.LINE_TO
											    ] ),
				               Vector.<Number>( [ 8.25, 13.75,
								                  4.25, 9.75,
												  8.75, 14,
												  12.75, 9.5,
												  8.5, 3.5,
												  8.5, 14.5
							   ] )
							   
							   );
		}
		
		override protected function measure():void
		{
			contentWidth  = 17.5;
			contentHeight = 17.5;
		}
		
	}
}