
// ---------if test on github pages-------------
let data;
fetchData()

function fetchData() {
    fetch("data.json")
        .then(response => response.json())
        .then(response => {
            data = JSON.parse(JSON.stringify(response))
        })
    .catch(error => console.error('Error while loading JSON:', error));
}

// -------if local testing----------------
// let jsonData = `[
//   {"Name": "Lion", "Color": "Yellow"},
//   {"Name": "Monkey", "Color": "Orange"},
//   {"Name": "Fish", "Color": "Blue"},
//   {"Name": "Cat", "Color": "Black"}
// ]`
// let data = JSON.parse(jsonData)


function startSearch() {
    const searchTerm = document.getElementById('searchInput').value;
    const searchResults = document.querySelector('#searchResults');
    searchResults.innerHTML = "";


    // Find with filter:
    const filterdData = data.filter(item => item.Name.includes(searchTerm))
    console.log(filterdData)
    const listItem = document.createElement('li');
    listItem.innerHTML = `${filterdData[0].Name} - ${filterdData[0].Color}`
    searchResults.appendChild(listItem);

    // Find item with for each
    data.forEach(item => {
        if (item.Name.includes(searchTerm)) {
            const listItem = document.createElement('li');
            listItem.innerHTML = `${item.Name} - ${item.Color}`
            searchResults.appendChild(listItem);
        }
    });
}