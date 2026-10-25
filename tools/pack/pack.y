import vault;
import fs;

const names = ["data/meshes.txt", "data/sprites.txt", "data/actors.txt", "data/world.txt", "data/script.txt"];
let parts: [str] = [];
foreach (n in names) {
    let t = fs.read_file(n);
    if (t == none) {
        print("pack: cannot read ", n);
        exit(1);
    };
    parts += t!;
};
let blob = vault.seal(parts);
if (!fs.write_file("build/data.pack", blob)) {
    print("pack: cannot write build/data.pack");
    exit(1);
};

if (!vault.open(blob)) { print("pack: the container does not open"); exit(1); };
for i in 0..len(names) {
    let back = vault.get(i);
    if (back == none || back! != parts[i]) { print("pack: ", names[i], " came back different"); exit(1); };
};
print("packed ", len(blob), " bytes in ", vault.nparts(), " parts");
