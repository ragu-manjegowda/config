use std::env;
use std::fs::{self, File};
use std::path::PathBuf;
use std::process::Command;

fn main() {
    let home = env::var("HOME").expect("HOME not set");
    let nltk_dir = PathBuf::from(&home).join(".cache/nltk_data/corpora");
    let zip_path = nltk_dir.join("wordnet.zip");
    let wordnet_dir = nltk_dir.join("wordnet");

    // Check if zip exists, if not download via NLTK
    if !zip_path.exists() {
        println!("cargo:warning=WordNet not found, downloading via NLTK...");

        let status = Command::new("python")
            .args([
                "-c",
                &format!(
                    "import nltk; nltk.download('wordnet', download_dir='{}')",
                    nltk_dir.parent().unwrap().display()
                ),
            ])
            .status()
            .expect("Failed to run python");

        if !status.success() {
            panic!("Failed to download WordNet via NLTK");
        }
    }

    // Check if extracted, if not unzip
    if !wordnet_dir.join("index.noun").exists() {
        println!("cargo:warning=Extracting WordNet...");

        let file = File::open(&zip_path).expect("Failed to open wordnet.zip");
        let mut archive = zip::ZipArchive::new(file).expect("Failed to read zip");

        for i in 0..archive.len() {
            let mut file = archive.by_index(i).expect("Failed to read zip entry");
            let outpath = nltk_dir.join(file.name());

            if file.is_dir() {
                fs::create_dir_all(&outpath).ok();
            } else {
                if let Some(p) = outpath.parent() {
                    fs::create_dir_all(p).ok();
                }
                let mut outfile = File::create(&outpath).expect("Failed to create file");
                std::io::copy(&mut file, &mut outfile).expect("Failed to extract");
            }
        }
    }

    println!("cargo:rerun-if-changed=build.rs");
}
