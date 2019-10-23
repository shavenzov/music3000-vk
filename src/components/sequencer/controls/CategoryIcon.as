package components.sequencer.controls
{
	import components.controls.CachedImage;

	public class CategoryIcon extends CachedImage
	{
		private var _category  : String;
		
		public function CategoryIcon() : void
		{
			super();
		}
		
		public function get category() : String
		{
			return _category;
		}
		
		public function set category( value : String ) : void
		{
			if ( value == _category )
			{
				return;
			}
			
			_category = value;
					
			var cD : Object = Settings.getCategoryDescription( _category );
			
			if ( cD.id )
			{
				url = cD.icon;
				toolTip = cD.label;
			}
			else
			{
				url = null;
				toolTip = null;
			}
		}
		
		override protected function measure():void
		{
			measuredWidth  = measuredMinWidth  = 48;
			measuredHeight = measuredMinHeight = 48;
		}
	}
}