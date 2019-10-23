package components.controls.users
{
	import classes.api.social.vk.VKApi;
	
	import mx.collections.ArrayCollection;
	import mx.core.ClassFactory;
	import mx.core.FlexGlobals;
	import mx.events.FlexEvent;
	
	import spark.events.IndexChangeEvent;

	public class HUsersList extends ScrollableList
	{
		public function HUsersList()
		{
			super();
			
			itemRendererFunction = selectRenderer;
			
			var items : Array = [ { invite : 'inviteItem' }, VKApi.userInfo ];
			
			if ( VKApi.appUsers && ( VKApi.appUsers.length > 0 ) )
			{
				items = items.concat( VKApi.appUsers );	
			}
			
			//Пригласить друга
			//items.push( { invite : 'inviteItem' } );
			
			
			dataProvider = new ArrayCollection( items );
			selectedIndex = 1;
			
			addEventListener( IndexChangeEvent.CHANGING, onIndexChanging );
			
			focusEnabled = false;
			
			addEventListener( FlexEvent.CREATION_COMPLETE, onCreationComplete );
		}
		
		private function onCreationComplete( e : FlexEvent ) : void
		{
			if ( ! focusManager )
			{
				focusManager = FlexGlobals.topLevelApplication.focusManager;
			}
		}
		
		private function onIndexChanging( e : IndexChangeEvent ) : void
		{
			//Шелкнули на кнопке "Пригласить друзей"
			if ( e.newIndex == 0/*( dataProvider.length - 1 )*/ )
			{
				e.preventDefault();
				VKApi.impl.callMethod( 'showInviteBox' );		
			}
		}
		
		private function selectRenderer( item : Object ) : ClassFactory
		{
			if ( item.invite )
			{
				return InviteItemRenderer;
			}
			
			return UserItemRenderer;
		}
		
		private static const UserItemRenderer   : ClassFactory = new ClassFactory( UserItem );
		private static const InviteItemRenderer : ClassFactory = new ClassFactory( InviteUserItem );
	}
}