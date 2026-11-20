
import slot_pool;

struct Entity {
    network_id: i64,
    hp: i32,
    team: i32
}

fn main() {
    var entities = slot_pool<Entity> {};

    // Создаём противника.
    let enemy .= entities.alloc_ref(
        Entity {
            network_id: 1001,
            hp: 100,
            team: 2
        }
    );

    // Сохраняем его индекс.
    let enemy_index = entities.items.index_of(enemy);

    print("Spawned enemy: ", enemy.network_id);
    print("Enemy slot: ", enemy_index);

    // Уничтожаем противника.
    entities.free(enemy_index);

    // Создаём игрока.
    let player .= entities.alloc_ref(
        Entity {
            network_id: 9001,
            hp: 500,
            team: 1
        }
    );

    let player_index = entities.items.index_of(player);

    print("Spawned player: ", player.network_id);
    print("Player slot: ", player_index);

    // ПОЗДНО ПРИЛЕТЕВШЕЕ СОБЫТИЕ!
    // Старый снаряд всё ещё помнит индекс противника.

    print("Projectile hits entity: ", enemy_index);

    entities.items[enemy_index].hp -= 50;

    print("Enemy reference now points to: ",
          enemy.network_id);

    print("Player HP: ", player.hp);
}


// . Представим игровой движок
// У нас есть ECS (Entity Component System), как в Unity DOTS, Bevy или собственном движке.

// В игре одновременно существуют:
// - Player — игрок.
// - Enemy — противник.
// - Projectile — снаряд.
// - Explosion — эффект взрыва.
// Для экономии памяти мы используем slot_pool: уничтоженные сущности не удаляются физически, а их слоты переиспользуются.






















// 9











// 2. Код на Goose, воспроизводящий баг
// В Goose есть готовый модуль slot_pool, который как раз предназначен для подобных сценариев.

// import slot_pool;

// struct Entity {
//     network_id: i64,
//     hp: i32,
//     team: i32
// }

// fn main() {
//     var entities = slot_pool<Entity> {};

//     // Создаём противника.
//     let enemy .= entities.alloc_ref(
//         Entity {
//             network_id: 1001,
//             hp: 100,
//             team: 2
//         }
//     );

//     // Сохраняем его индекс.
//     let enemy_index = entities.items.index_of(enemy);

//     print("Spawned enemy: ", enemy.network_id);
//     print("Enemy slot: ", enemy_index);

//     // Уничтожаем противника.
//     entities.free(enemy_index);

//     // Создаём игрока.
//     let player .= entities.alloc_ref(
//         Entity {
//             network_id: 9001,
//             hp: 500,
//             team: 1
//         }
//     );

//     let player_index = entities.items.index_of(player);

//     print("Spawned player: ", player.network_id);
//     print("Player slot: ", player_index);

//     // ПОЗДНО ПРИЛЕТЕВШЕЕ СОБЫТИЕ!
//     // Старый снаряд всё ещё помнит индекс противника.

//     print("Projectile hits entity: ", enemy_index);

//     entities.items[enemy_index].hp -= 50;

//     print("Enemy reference now points to: ",
//           enemy.network_id);

//     print("Player HP: ", player.hp);
// }



// Воспроизводимая логическая ошибка
// Важная особенность: slot_pool использует LIFO-переиспользование слотов. Поэтому только что освобождённый слот будет использован следующим.

// Ожидаемая последовательность:
// Spawned enemy: 1001
// Enemy slot: 0

// Spawned player: 9001
// Player slot: 0

// Projectile hits entity: 0

// Enemy reference now points to: 9001
// Player HP: 450


// Снаряд, выпущенный по противнику, нанёс урон игроку.

// И самое неприятное: программа полностью корректна с точки зрения обращения к памяти.
// 3. Почему Goose это разрешает?
// Вот здесь начинается самое интересное.

// Goose гарантирует, что ссылка не превратится в dangling pointer из-за освобождения памяти: слот остаётся физически существующим и содержит корректное значение.

// Но free() в slot_pool не уничтожает содержимое слота и не инвалидирует существующие ссылки.

// Когда слот переиспользуется, старая ссылка начинает видеть новый объект.

// Это прямо предусмотренное поведение библиотеки. 
// Goose+1

// Жизненный цикл одного слота
// T = 0
// Slot 0 — Enemy
// ID: 1001
// HP: 100


// T = 1
// Enemy уничтожен

// Слот освобождён, но старые ссылки ещё существуют.


// T = 2
// Slot 0 — Player
// ID: 9001
// HP: 500


// Старое событие ProjectileHit

// Оно содержит индекс 0 и не знает, что сущность уже заменена.
// Player HP: 450


// 4. Как исправляют это в игровых движках?
// Используют Generational Entity Handles — идентификаторы с поколениями.

// Вместо простого индекса:
// EntityHandle = 0


// хранят пару:
// EntityHandle {
//     index: 0,
//     generation: 7
// }


// Когда слот освобождается и используется повторно, поколение увеличивается:
// Состояние	Index	Generation
// Старый Enemy	0	7
// Новый Player	0	8

// Снаряд хранит (0, 7), а текущий игрок имеет (0, 8).

// При обработке события:
// if handle.generation != slot.generation {
//     reject_stale_event();
// }


// Снаряд обнаруживает, что его цель уже не существует.

// Важный нюанс: generation counter должен увеличиваться при каждом новом использовании слота, а не только при создании новой сущности. Также нужно предусмотреть переполнение счётчика поколений.
// 5. Почему это настоящий игровой кошмар?
// Такая ошибка может проявляться в самых неожиданных местах:
// Игровая система	Последствия
// Projectile system	Снаряды атакуют новых сущностей
// AI system	Старый AI управляет новым NPC
// Physics engine	Контакт относится к уже другой сущности
// Animation system	Анимация старого персонажа применяется к новому
// Network replication	Запоздалый пакет изменяет новую сущность
// Particle system	Эффект привязывается к чужому объекту

// Особенно опасен multiplayer: сетевой пакет может задержаться на несколько кадров, а за это время слот уже успеет получить совершенно другую сущность.

// 6. Что мы проверили в Goose?
// Механизм	Результат
// Stable storage	Слот не перемещается
// Memory safety	Ссылка остаётся валидной
// Slot reuse	Разрешён
// Stale references	Могут видеть замену
// Automatic generation validation	Нет
// Generational handles	Нужно реализовать на уровне приложения

// Документация: Goose Standard Library — slot_pool.

// Вот это уже очень показательный эксперимент для GameDev. Он демонстрирует, что memory-safe язык не обязательно защищает от ошибок идентичности игровых объектов.

// И я бы даже назвал это более интересным испытанием Goose, чем обычный use-after-free: здесь программа не падает, не выдаёт ошибку и не повреждает память. Она совершенно спокойно наносит 50 единиц урона совершенно не тому персонажу.