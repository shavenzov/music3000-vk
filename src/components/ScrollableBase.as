package components
{
	import flash.geom.Rectangle;

	public class ScrollableBase extends Base
	{
		/**
		 * Вкл/выкл отсечения и включения прокрутки 
		 */		
		public var clipAndEnableScrolling : Boolean = true;
		
		/**
		 * Значение прокрутки по горизонтали 
		 */		
		protected var _hsp : Number = 0;
		
		/**
		 * Значение прокрутки по вертикали 
		 */		
		protected var _vsp : Number = 0;
		
		/**
		 * Сиволизирует о необходимости обновить прокручиваемую область 
		 */		
		protected var _scrollRectChanged : Boolean;
		
		/**
		 * Размер отсекаемой области по горизонтали 
		 */		
		protected var _scrollWidth : Number = 0;;
		
		/**
		 * Размер отсекаемой области по вертикали 
		 */		
		protected var _scrollHeight : Number = 0;
		
		public function ScrollableBase()
		{
			super();
		}	
		
		public function get scrollWidth() : Number
		{
			return _scrollWidth;
		}
		
		public function set scrollWidth( value : Number ) : void
		{
			if ( value != _scrollWidth )
			{
				_scrollWidth = value;
				_scrollRectChanged = true;
			}	
		}
		
		public function get scrollHeight() : Number
		{
			return _scrollHeight;
		}
		
		public function set scrollHeight( value : Number ) : void
		{
			if ( value != _scrollHeight )
			{
				_scrollHeight = value;
				_scrollRectChanged = true;
			}	
		}	
		
		public function get hsp() : Number
		{
			return _hsp;
		}
		
		public function set hsp( value : Number ) : void
		{
			if ( value != _hsp )
			{
				if ( value > contentWidth )
				{
					_hsp = scrollWidth < contentWidth - scrollWidth ? contentWidth : 0;
				}
				else
				{
					_hsp = value;
				}
				
				_scrollRectChanged = true;
			}
		}
		
		public function get vsp() : Number
		{
			return _vsp;
		}
		
		public function set vsp( value : Number ) : void
		{	
			if ( value != _vsp )
			{
				if ( value > contentHeight )
				{
					_vsp = scrollHeight < contentHeight - scrollHeight ? contentHeight : 0;
				}
				else
				{
					_vsp = value;
				}
				
				_scrollRectChanged = true;
			}
		}
		
		public function updateScrollRect():void
		{
			if ( clipAndEnableScrolling )
			{	
				if ( _scrollRectChanged )
				{
					scrollRect = new Rectangle( _hsp, _vsp, _scrollWidth, _scrollHeight );
					_scrollRectChanged = false;
				}
			}
			else scrollRect = null;
		}
	}
}