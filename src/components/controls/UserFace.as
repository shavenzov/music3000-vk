package components.controls
{
	import com.utils.ImageUtil;
	
	import flash.display.BlendMode;
	import flash.display.DisplayObject;
	
	import mx.utils.GraphicsUtil;

	public class UserFace extends CachedImage
	{
		private var proIcon : DisplayObject;
		private var _pro : Boolean;
		private var _proChanged : Boolean;
		
		public function UserFace()
		{
			super();
		}
		
		public function get pro() : Boolean
		{
			return _pro;
		}
		
		public function set pro( value : Boolean ) : void
		{
			if ( _pro != value )
			{
				_pro = value;
				_proChanged = true;
				invalidateDisplayList();
			}
		}
		
		
		override protected function getDummyImage() : DisplayObject
		{
			var s : DisplayObject = new Assets.FRIEND_INVITED_ICON();
			
			ImageUtil.resizeTo( s, 50.0 );
			
			return s;
		}
		
		override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void
		{
			super.updateDisplayList( unscaledWidth, unscaledHeight );
			
			if ( _proChanged )
			{
				if ( proIcon )
				{
					removeChild( proIcon );
					proIcon = null;
				}
				
				if ( _pro )
				{
					proIcon = new Assets.PRO_MODE_ICON();
					//proIcon.blendMode = BlendMode.SUBTRACT;
					addChild( proIcon );
				}
			    
				_proChanged = false;
			}
			
			if ( proIcon )
			{
				if ( image )
				{
					proIcon.x = unscaledWidth  - proIcon.width;
					proIcon.y = unscaledHeight - proIcon.height;
				}
			}
		}
		
		
	}
}