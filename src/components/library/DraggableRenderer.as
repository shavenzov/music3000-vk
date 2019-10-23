package components.library
{
	import flash.events.MouseEvent;
	
	import spark.components.supportClasses.ItemRenderer;
	
	public class DraggableRenderer extends ItemRenderer
	{
		/**
		 * Величина на которую должен сместиться семпл для начала процесса перетаскивания 
		 */		
		private var _startDraggingOffset : Number = 10;
		/**
		 * Событие возникшее при нажатии клавиши мыши 
		 */		
		private var _mouseDownEvent      : MouseEvent;
		
		public function DraggableRenderer()
		{
			super();
			
			addEventListener( MouseEvent.MOUSE_DOWN, onMouseDown );
		}
		
		private function onMouseDown( e : MouseEvent ) : void
		{
		    _mouseDownEvent = e;
			
			systemManager.getSandboxRoot().addEventListener( MouseEvent.MOUSE_UP, onMouseUp );
			systemManager.getSandboxRoot().addEventListener( MouseEvent.MOUSE_MOVE, onMouseMove );
		}
		
		private function onMouseUp( e : MouseEvent ) : void
		{
			systemManager.getSandboxRoot().removeEventListener( MouseEvent.MOUSE_UP, onMouseUp );
			systemManager.getSandboxRoot().removeEventListener( MouseEvent.MOUSE_MOVE, onMouseMove );
		}
		
		private function onMouseMove( e : MouseEvent ) : void
		{
			if ( ( Math.abs( _mouseDownEvent.stageX - e.stageX ) > _startDraggingOffset ) ||
				 ( Math.abs( _mouseDownEvent.stageY - e.stageY ) > _startDraggingOffset ) )
			{
				onMouseUp( null );
				startDragging( e );
			}
		}
		
		protected function startDragging( event : MouseEvent ) : void
		{
			
		}	
		/*
		private function startDragging( event : MouseEvent ) : void
		{
			var s : SampleDescription = SampleDescription( data );
			
			var dragImage  : VisualSampleDragDropDummy = new VisualSampleDragDropDummy();
			    dragImage.data = s;
				dragImage.originalColor = 0x0099FF;
			
			var initEvent : MouseEvent = new MouseEvent( event.type, event.bubbles, event.cancelable, measuredWidth / 2, measuredHeight / 2, event.relatedObject );	
			
			var dragSource : DragSource = new DragSource();
			    dragSource.addData( s, 'sample' );
			    dragSource.addData( dragImage, 'dragImage' );
			
			DragManager.doDrag( this, dragSource, initEvent, dragImage, 0, 0, 1 ); 	
		}
		*/
	}
}