package components.sequencer
{
	import components.sequencer.baseClasses.BaseLoopable;
	import classes.BaseDescription;
	
	public class VisualSampleDropCursor extends BaseLoopable
	{
		private var _sampleDescriptor : BaseDescription;
		private var _descriptorChanged : Boolean;
		
		[Bindable]
		public var color : uint;
		
		public function VisualSampleDropCursor()
		{
			super();
		}
		
		public function get sampleDescriptor() : BaseDescription
		{
			return _sampleDescriptor;
		}
		
		public function set sampleDescriptor( value : BaseDescription ) : void
		{
			_sampleDescriptor = value;
			_descriptorChanged = true;
			invalidateProperties();
		}
		
		override protected function commitProperties():void
		{
			super.commitProperties();
			
			if ( _descriptorChanged )
			{
				update();
				_descriptorChanged = false;
			}	
		}
		
		private function update() : void
		{
			//timeDuration = _sampleDescriptor.duration;
		}	
	}
}