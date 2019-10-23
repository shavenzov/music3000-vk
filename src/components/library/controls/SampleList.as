package components.library.controls
{
	import mx.collections.ArrayCollection;
	import mx.collections.IList;
	import mx.core.IDataRenderer;
	import mx.core.IVisualElement;
	
	import spark.components.List;
	import spark.layouts.VerticalLayout;
	
	import classes.BaseDescription;
	import classes.PaletteSample;
	import classes.SamplesPalette;
	import classes.Sequencer;
	import classes.api.MainAPI;
	import classes.api.MainAPIImplementation;
	import classes.api.events.FavoriteEvent;
	
	import components.library.controls.events.FavoriteSampleEvent;
	
	public class SampleList extends List
	{
		private var api : MainAPIImplementation;
		
		/**
		 * Список операций выполняемых в настоящий момент 
		 */		
		private var addOp    : Vector.<FavoriteSampleEvent>;
		private var removeOp : Vector.<FavoriteSampleEvent>;
		
		public function SampleList()
		{
			super();
			
			api = MainAPI.impl;
			
			addOp    = new Vector.<FavoriteSampleEvent>();
			removeOp = new Vector.<FavoriteSampleEvent>();
			
			addEventListener( FavoriteSampleEvent.ADD_TO_FAVORITE, onFavoriteOperationBegin );
			addEventListener( FavoriteSampleEvent.REMOVE_FROM_FAVORITE, onFavoriteOperationBegin );
		}
		
		private function onFavoriteOperationBegin( e : FavoriteSampleEvent ) : void
		{	
			var description : BaseDescription = BaseDescription( e.data );
			    description.favoriteChanging = true;
				
				updateRenderers( description );
				
			if ( e.type == FavoriteSampleEvent.ADD_TO_FAVORITE )
		    {
			  if ( addOp.length == 0 )
			  {
				  api.addListener( FavoriteEvent.ADD, onFavoriteOperationEnd, this );
			  }
			  
			  addOp.push( e );
			  api.addToFavorite( description.sourceID, description.sampleID );
			  
			  return;
		    }
		  
		    if ( e.type == FavoriteSampleEvent.REMOVE_FROM_FAVORITE )
		    {
			  if ( removeOp.length == 0 )
			  {
				  api.addListener( FavoriteEvent.REMOVE, onFavoriteOperationEnd, this );
			  }
			  
			  removeOp.push( e );
			  api.removeFromFavorite( description.sourceID, description.sampleID );
		    } 
		}
		
		private function onFavoriteOperationEnd( e : FavoriteEvent ) : void
		{
			if ( e.type == FavoriteEvent.ADD )
			{
				endOperation( addOp, e.hash, e.library, e );
				
				if ( addOp.length == 0 )
				{
					api.removeListener( FavoriteEvent.ADD, onFavoriteOperationEnd );
				}
				
				return;
			}
			
			if ( e.type == FavoriteEvent.REMOVE )
			{
				endOperation( removeOp, e.hash, e.library, e );
				
				if ( removeOp.length == 0 )
				{
					api.removeListener( FavoriteEvent.REMOVE, onFavoriteOperationEnd );
				}
			}
		}
		
		private function endOperation( operations : Vector.<FavoriteSampleEvent>, sampleID : String, sourceID : String, event : FavoriteEvent ) : void
		{
			for ( var i : int = 0; i < operations.length; i ++ )
			{
				var operation   : FavoriteSampleEvent = operations[ i ];
				var description : BaseDescription     = BaseDescription( operation.data );
				var sid         : String              = BaseDescription.serializeSampleID( sampleID, sourceID );
				
				if ( description.id == sid )
				{
					//Удаляем поле "Идет изменение св-ва favorite"
					description.favoriteChanging = false;
					
					//Изменяем состояние поля favorite
					if ( ! event.error )
					{
						description.favorite = event.type == FavoriteEvent.ADD;
					}
					
					updateRenderers( description );
				
					operations.splice( i, 1 );
					
					/*
					!!!
					Если изменить состояние favorite сэмплов в projects, то если сэмпл не виден в данный момент на экране, то favorite не обновится в sampleLibary и acapellaLibrary
					!!!
					*/
					
					break;
				}
			}
		}
		
		private function updateRenderers( description : BaseDescription ) : void
		{
			//Обновляем ItemRenderer всех отображаемых списков
			updateVisibleRenderers( ApplicationModel.library.samples.result, description );
			updateVisibleRenderers( ApplicationModel.library.acapellas.result, description );
			
			updateAllRenderers( ApplicationModel.library.projects.result, description );
		}
		
		private function updateAllRenderers( list : List, description : BaseDescription ) : void
		{
			if ( ! updateVisibleRenderers( list, description ) )
			{
				var palette : SamplesPalette = Sequencer.impl.palette;
				var sample  : PaletteSample  = palette.getSample( description.id );
				
				if ( sample )
				{
					sample .description.favorite         = description.favorite;
					sample .description.favoriteChanging = description.favoriteChanging;
				}
			}
		}
		
		private function updateVisibleRenderers( list : List, description : BaseDescription ) : Boolean
		{
			if ( ! list )
			{
				return false;
			}
			
			var vLayout    : VerticalLayout = VerticalLayout( list.layout );
			var firstIndex : int            = vLayout.firstIndexInView;
			var lastIndex  : int            = vLayout.lastIndexInView; 
			
			for ( var index : int = firstIndex; index <= lastIndex; index ++ ) 
			{
				var renderer : IVisualElement = list.dataGroup.getElementAt( index ) as IVisualElement;
				
				if ( renderer )
				{
					var dataRenderer : IDataRenderer = renderer as IDataRenderer;
					
					if ( dataRenderer )
					{
						if ( dataRenderer.data.id == description.id )
						{
							list.updateRenderer( renderer, index, description );
							return true;
						}
					}
				}
			}
			
			return false;
		}
	}
}