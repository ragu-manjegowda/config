use std::env;
use std::fs::OpenOptions;
use std::io::Write;
use std::path::PathBuf;
use std::process::Command;

use nlprule::{tokenizer_filename, Tokenizer};
use wordnet_db::WordNet;
use wordnet_types::{Pos, SynsetId};

static TOKENIZER_BYTES: &[u8] = include_bytes!(concat!(
    env!("NLPRULE_CACHE_DIR"),
    "/",
    tokenizer_filename!("en")
));

fn log_debug(msg: &str) {
    if let Ok(home) = env::var("HOME") {
        let log_path = PathBuf::from(home).join(".cache/sioyek-dict.log");
        if let Ok(mut f) = OpenOptions::new().create(true).append(true).open(log_path) {
            let _ = writeln!(f, "{}", msg);
        }
    }
}

fn main() {
    let args: Vec<String> = env::args().collect();
    log_debug(&format!("Args: {:?}", args));

    if args.len() < 3 {
        log_debug("Error: less than 3 args");
        return;
    }

    let sioyek_path = args[1].trim_matches('"');
    let text = args[2].trim_matches('"').trim();
    log_debug(&format!("sioyek_path: {}, text: '{}'", sioyek_path, text));

    let word: String = text
        .chars()
        .take_while(|c| c.is_alphanumeric() || *c == '-')
        .collect();

    if word.is_empty() {
        set_status(sioyek_path, "No word selected");
        return;
    }

    let mut tokenizer_bytes = TOKENIZER_BYTES;
    let tokenizer = match Tokenizer::from_reader(&mut tokenizer_bytes) {
        Ok(t) => t,
        Err(e) => {
            log_debug(&format!("Failed to load tokenizer: {}", e));
            set_status(sioyek_path, "Tokenizer error");
            return;
        }
    };

    match lookup_word(&word, &tokenizer) {
        Some(def) => set_status(sioyek_path, &format!("{}: {}", word, def)),
        None => set_status(sioyek_path, &format!("No definition: {}", word)),
    }
}

fn nlprule_pos_to_wordnet(pos_tag: &str) -> Option<Pos> {
    match pos_tag {
        s if s.starts_with("NN") => Some(Pos::Noun),
        s if s.starts_with("VB") => Some(Pos::Verb),
        s if s.starts_with("JJ") => Some(Pos::Adj),
        s if s.starts_with("RB") => Some(Pos::Adv),
        _ => None,
    }
}

fn pos_to_name(pos: Pos) -> &'static str {
    match pos {
        Pos::Noun => "noun",
        Pos::Verb => "verb",
        Pos::Adj => "adj",
        Pos::Adv => "adv",
    }
}

#[derive(Debug, Clone)]
struct LemmaInfo {
    lemma: String,
    pos: Option<Pos>,
}

fn get_lemmas(word: &str, tokenizer: &Tokenizer) -> Vec<LemmaInfo> {
    let mut lemmas = Vec::new();
    let mut seen = std::collections::HashSet::new();

    for sentence in tokenizer.pipe(word) {
        for token in sentence.tokens() {
            for word_data in token.word().tags() {
                let lemma_str = word_data.lemma().as_str().to_lowercase();
                let pos_tag = word_data.pos().as_str();
                let pos = nlprule_pos_to_wordnet(pos_tag);

                let key = (lemma_str.clone(), pos);
                if !seen.contains(&key) {
                    seen.insert(key);
                    lemmas.push(LemmaInfo {
                        lemma: lemma_str,
                        pos,
                    });
                }
            }
        }
    }

    let word_lower = word.to_lowercase();
    if !seen.iter().any(|(l, _)| l == &word_lower) {
        lemmas.push(LemmaInfo {
            lemma: word_lower,
            pos: None,
        });
    }

    lemmas
}

fn lookup_word(word: &str, tokenizer: &Tokenizer) -> Option<String> {
    let home = env::var("HOME").ok()?;
    let wordnet_dir = PathBuf::from(home).join(".cache/nltk_data/corpora/wordnet");

    let wn = WordNet::load(&wordnet_dir).ok()?;
    let lemmas = get_lemmas(word, tokenizer);

    log_debug(&format!("Lemmas for '{}': {:?}", word, lemmas));

    for info in &lemmas {
        let pos_list: Vec<Pos> = match info.pos {
            Some(p) => vec![p],
            None => vec![Pos::Noun, Pos::Verb, Pos::Adj, Pos::Adv],
        };

        for pos in pos_list {
            if let Some(entry) = wn.index_entry(pos, &info.lemma) {
                if let Some(&offset) = entry.synset_offsets.first() {
                    let synset_id = SynsetId { pos, offset };
                    if let Some(synset) = wn.get_synset(synset_id) {
                        let def = synset.gloss.definition;
                        let display_lemma = if info.lemma != word.to_lowercase() {
                            format!(" ({})", info.lemma)
                        } else {
                            String::new()
                        };
                        return Some(format!("[{}]{} {}", pos_to_name(pos), display_lemma, def));
                    }
                }
            }
        }
    }
    None
}

fn set_status(sioyek_path: &str, msg: &str) {
    let msg = if msg.len() > 200 { &msg[..200] } else { msg };
    let msg = msg.replace('(', "[").replace(')', "]");
    let _ = Command::new(sioyek_path)
        .args([
            "--execute-command",
            "set_status_string",
            "--execute-command-data",
            &msg,
        ])
        .spawn();
}
