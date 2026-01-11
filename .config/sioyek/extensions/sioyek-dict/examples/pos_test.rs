use nlprule::{tokenizer_filename, Tokenizer};

static TOKENIZER_BYTES: &[u8] = include_bytes!(concat!(
    env!("NLPRULE_CACHE_DIR"),
    "/",
    tokenizer_filename!("en")
));

fn main() {
    let words = ["running", "dogs", "went", "better", "quickly"];

    let mut tokenizer_bytes = TOKENIZER_BYTES;
    let tokenizer = Tokenizer::from_reader(&mut tokenizer_bytes).unwrap();

    for word in words {
        println!("\n=== {} ===", word);
        for sentence in tokenizer.pipe(word) {
            for token in sentence.tokens() {
                println!("Text: '{}'", token.word().as_str());
                for data in token.word().tags() {
                    println!(
                        "  lemma: {:?}, pos: {:?}",
                        data.lemma().as_str(),
                        data.pos().as_str()
                    );
                }
            }
        }
    }
}
