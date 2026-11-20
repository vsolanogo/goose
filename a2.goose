
fn calculate_payout(total_cents: i32, adjustment: i32) -> i32 {
    // BUG: результат может оказаться отрицательным.
    total_cents - adjustment
}

fn main() {
    let total_cents: i32 = 20;
    let adjustment: i32 = 40;

    let win = calculate_payout(total_cents, adjustment);

    // BUG: принудительно интерпретируем отрицательное
    // значение как беззнаковое 32-битное число.
    let unsigned = win as! u32;

    // Переводим центы в доллары.
    let dollars = unsigned as f64 / 100.0;

    print("=== Sphinx Slot Machine ===");
    print("printing cash ticket $", dollars);
    print("(internal signed value: ", win, " cents)");
}
