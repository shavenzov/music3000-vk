package components.controls
{
	import flash.display.DisplayObject;
	import flash.events.Event;
	import flash.events.MouseEvent;
	
	import mx.core.UIComponent;
	import mx.core.mx_internal;
	import mx.events.FlexEvent;
	
	use namespace mx_internal;
	
	[Event(name="select", type="flash.events.Event")]
	public class SortButton extends components.controls.LinkButton
	{
		private var arrowIcon : DisplayObject;
		
		/**
		 *  По возрастанию или убыванию
		 */		
		private var _descending : Boolean;
		private var _descending_changed : Boolean;
		
		public function SortButton()
		{
			super();
			toggle = true;
			addEventListener( MouseEvent.CLICK, onClick, false, 1000 );
		}
		
		/**
		 * Названия поля сортировки связанного с этим контролом 
		 */		
		public var sortField : String;
		
		override public function set selected( value : Boolean ) : void
		{
			super.selected = value;
			_descending_changed = true;
		}
		
		private function onClick( e : MouseEvent ) : void
		{
			_descending_changed = true;
			
			if ( selected )
			{
				_descending = ! _descending;
				invalidateDisplayList();
				e.stopImmediatePropagation();
				dispatchEvent( new Event( Event.SELECT ) );
			}
		}
		
		public function get descending() : Boolean
		{
			return _descending;
		}
		
		public function set descending( value : Boolean ) : void
		{
			_descending = value;
			_descending_changed = true;
			invalidateProperties();
		}
		
		private function getArrowIcon() : DisplayObject
		{
			return DisplayObject( _descending ? new Assets.ASC_SORT_ICON : new Assets.DESC_SORT_ICON() );
		}
		
		private function updateState() : void
		{
			if ( arrowIcon )
			{
				removeChild( arrowIcon );
				arrowIcon = null;
			}
			
			if ( selected )
			{
				arrowIcon = getArrowIcon();
				addChild( arrowIcon );
			}
		}
		/*
		override protected function commitProperties():void
		{
			super.commitProperties();
		}
		*/
		override protected function measure() : void
		{
			super.measure();
			
			/*if ( arrowIcon )
			{
				measuredWidth  += arrowIcon.width;
				measuredHeight += Math.max( measuredHeight, arrowIcon.height );
				
				measuredMinWidth = measuredWidth;
				measuredMinHeight = measuredHeight;
			}*/
		}
		
		override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void
		{
			super.updateDisplayList( unscaledWidth, unscaledHeight );
			
			if ( _descending_changed )
			{
				updateState();
				
				if ( arrowIcon )
				{
					arrowIcon.y = ( unscaledHeight - arrowIcon.height ) / 2;
		            arrowIcon.x = - arrowIcon.width;
				}
				
				_descending_changed = false;
			}
		}
	}
}