package components.menu.renderers
{
	import mx.controls.menuClasses.MenuItemRenderer;
	import mx.controls.listClasses.BaseListData;
	import mx.controls.listClasses.ListBase;

	public class MenuItemRenderer extends mx.controls.menuClasses.MenuItemRenderer
	{
		
		private var _itemPaddingLeft   : Number = 0;
		private var _itemPaddingRight  : Number = 0;
		private var _itemPaddingBottom : Number = 0;
		private var _itemPaddingTop    : Number = 0;
		
		private var _useDelimiter       : Boolean = true;
		private var _delimiterThickness : Number = 1;
		private var _delimiterColor     : uint = 0x000000;
		
		private var _listData  : BaseListData;
        private var _listOwner : ListBase;
		
		public function MenuItemRenderer()
		{
			super();
		}
		
		override public function stylesInitialized():void
		 {
		 	var numValue : Number = getStyle( "leftIconGap" );
		 	if ( ! isNaN( numValue ) ) _itemPaddingLeft = numValue;
		 	
		 	numValue = getStyle( "rightIconGap" );
		 	if ( ! isNaN( numValue ) ) _itemPaddingRight = numValue;
		 	
		 	numValue = getStyle( "itemPaddingBottom" );
		 	if ( ! isNaN( numValue ) ) _itemPaddingBottom = numValue;
		 	
		 	numValue = getStyle( "itemPaddingTop" );
		 	if ( ! isNaN( numValue ) ) _itemPaddingTop = numValue;
		 	
		 	var strValue : String = getStyle( "useDelimiter" );
		 	if ( ( strValue ) && ( strValue == 'yes' ) ) _useDelimiter = true;
		 	 else _useDelimiter = false;
		 	 
		 	numValue = getStyle( "delimiterThickness" );
		 	if ( ! isNaN( numValue ) ) _delimiterThickness = numValue;
		 	
		 	var intValue : uint = getStyle( "delimiterColor" );
		 	_delimiterColor = intValue;	
		 }
		 
	   override public function set listData( value : BaseListData ) : void
        {
         super.listData = value;
         
         if ( value )
          {
           _listData = value;
           _listOwner = ListBase( _listData.owner );
           //_listOwner.addEventListener( ScrollEvent.SCROLL, onScroll );
           
           invalidateDisplayList();
         }
          
       }
	    
       override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void
       {
       	 super.updateDisplayList( unscaledWidth, unscaledHeight );
       	 
       	 if ( data && parent )
       	  {
       	    
       	    if ( _useDelimiter )
       	     {
       	  	   
       	  	   var itemIndex : int = _listData.rowIndex + _listOwner.verticalScrollPosition;
       	  	   
       	  	   graphics.clear();
       	  	   
       	  	   if ( itemIndex != ( _listOwner.dataProvider.length - 1 ) )
       	  	    {
       	  	      graphics.lineStyle( _delimiterThickness, _delimiterColor );
       	  	      graphics.moveTo( _itemPaddingLeft, unscaledHeight );
       	  	      graphics.lineTo( unscaledWidth - _itemPaddingRight, unscaledHeight );
       	  	    }     
       	     }
       	    
       	  } 
       	  
       }
       
      override protected function measure() : void
       {
       	 super.measure();
		 
       	 if ( data.label != '' )
		 {
			 measuredHeight += _itemPaddingTop + _itemPaddingBottom; 
		 }	  
       }   
       
	}
}