struct TransferResult {
    account: i32,  // 0 = Marcus, 1 = Lucius
    balance: i32,
}

thread_fn transfer(
    account:  i32,
    amount:   i32,
    snapshot: i32,
) {
    // Worker работает со своей копией snapshot.
    let new_balance = snapshot + amount;

    // Передаём результат главному потоку.
    qput(TransferResult {
        account: account,
        balance: new_balance,
    });
}

fn main() {
    var marcus: i32 = 1000;
    var lucius: i32 = 1000;

    print("Initial:");
    print("Marcus: ", marcus);
    print("Lucius: ", lucius);

    // Все операции используют снимки,
    // сделанные до получения результатов workers.

    var ids: i64[>..] = [];

    // Marcus -> Lucius: 150
    ids.push(thread_spawn(transfer, 1, 150, 1000));
    marcus -= 150;

    // Lucius -> Marcus: 200
    ids.push(thread_spawn(transfer, 0, 200, 850));
    lucius -= 200;

    // Marcus -> Lucius: 250
    ids.push(thread_spawn(transfer, 1, 250, 800));
    marcus -= 250;

    // Lucius -> Marcus: 300
    ids.push(thread_spawn(transfer, 0, 300, 600));
    lucius -= 300;

    // Marcus -> Lucius: 350
    ids.push(thread_spawn(transfer, 1, 350, 500));
    marcus -= 350;

    // Получаем результаты всех workers.
    for i in 5 {
        let result = qget<TransferResult>();

        if result.account == 0 {
            marcus = result.balance;
        } else {
            lucius = result.balance;
        }
    }

    // Дожидаемся завершения потоков.
    for id in ids {
        thread_wait(id);
    }

    print("Final:");
    print("Marcus: ", marcus);
    print("Lucius: ", lucius);
    print("Total: ", marcus + lucius);
}
