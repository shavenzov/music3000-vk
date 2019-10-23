package classes.api.data
{
	public dynamic class ProjectInfo
	{
		/**
		 * Название проекта 
		 */		
		public var name : String;
		/**
		 * Дата последнего обновления 
		 */		
		public var updated : Date;
		/**
		 * Дата создания 
		 */		
		public var created : Date;
		/**
		 * Указывает Жанр выбран из списка предопределенных констант или введен пользователем
		 * true  - введен пользователем
		 * false - Один из списка предопределенных констант 
		 */		
		public var userGenre : Boolean;
		/**
		 * Жанр 
		 */		
		public var genre : String;
		
		/**
		 * Идентификатор проекта 
		 */		
		public var id : int = -1;
		/**
		 * Идентификатор владельца 
		 */		
		public var owner : int = -1;
		/**
		 * Темп в ударах в минуту
		 */		
		public var tempo : int;
		/**
		 * Длительность в фреймах 
		 */		
		public var duration : int;
		/**
		 * Описание  
		 */		
		public var description : String;
		
		/**
		 * Уровень доступа к миксу другим пользователям 
		 */		
		public var access : String = ProjectAccess.FRIENDS;
		/**
		 * Другие пользователя могут, только посмотреть микс, но не редактировать или сохранить 
		 */		
		public var readonly : Boolean;
		
		public function clone() : ProjectInfo
		{
			var d : ProjectInfo = new ProjectInfo();
			    d.name = name;
				d.updated = updated ? new Date( updated.time ) : null;
				d.created = created ? new Date( created.time ) : null;
				d.userGenre = userGenre;
				d.genre = genre;
				d.id = id;
				d.owner = owner;
				d.tempo = tempo;
				d.duration = duration;
				d.description = description;
				d.access = access;
				d.readonly = readonly;
				
			return d;	
		}
	}
}