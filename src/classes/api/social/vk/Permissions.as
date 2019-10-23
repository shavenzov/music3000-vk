package classes.api.social.vk
{
	public class Permissions
	{
		/**
		 *Пользователь разрешил отправлять ему уведомления
		 */		
		public static const MESSAGES : int = 1;
		/**
		 * Доступ к друзьям
		 */		
		public static const FRIENDS : int = 2;
		/**
		 * Доступ к фотографиям
		 */	
		public static const PHOTOS : int = 3;
		/**
		 * Доступ к аудиозаписям
		 */
		public static const AUDIOS : int = 8;
		/**
		 * Доступ к видеозаписям
		 */
		public static const VIDEOS : int = 16;
		/**
		 * Добавление ссылки на приложение в меню слева
		 */
		public static const ADD_APPLICATION_TO_MENU : int = 256;
		/**
		 * Доступ к обычным и расширенным методам работы со стеной. 
		 */		
		public static const WALLS : int = 8192;
	}
}