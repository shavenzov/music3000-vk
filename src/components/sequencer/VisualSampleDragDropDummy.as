package components.sequencer
{
	import classes.BaseDescription;
	
	import spark.components.supportClasses.SkinnableComponent;
	
	public class VisualSampleDragDropDummy extends SkinnableComponent
	{	
		[Bindable]
		public var text : String;
		
		[Bindable]
		public var color : uint;
		
		public var originalColor : uint;
		
		private var _data : BaseDescription;
		private var _dataChanged : Boolean;
		
		public function VisualSampleDragDropDummy()
		{
			super();
		}
		
		public function get data() : BaseDescription
		{
			return _data;
		}
		
		public function set data( value : BaseDescription ) : void
		{
			_data = value;
			_dataChanged = true;
			invalidateProperties();
		}
		
		override protected function commitProperties():void
		{
			super.commitProperties();
			
			if ( _dataChanged )
			{
				update();
				_dataChanged = false;
			}	
		}
		
		private function update() : void
		{
			text = _data.name;
		}	
		
	}
}