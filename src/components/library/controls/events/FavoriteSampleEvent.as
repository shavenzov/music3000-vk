package components.library.controls.events
{
	import flash.events.Event;
	
	import spark.components.IItemRenderer;
	
	public class FavoriteSampleEvent extends Event
	{
		/**
		 * Инициировать процесс добавления сэмпла в список избранных 
		 */		
		public static const ADD_TO_FAVORITE : String = 'addToFavorite';
		
		/**
		 * Инициировать процесс удаления сэмпла из списка избранных 
		 */		
		public static const REMOVE_FROM_FAVORITE : String = 'removeFromFavorite';
		
		public var item : IItemRenderer;
		public var data : Object;
		
		public function FavoriteSampleEvent( type : String, item : IItemRenderer, data : Object )
		{
			super( type );
			
			this.item = item;
			this.data = data;
		}
		
		override public function clone() : Event
		{
			return new FavoriteSampleEvent( type, item, data );
		}
	}
}